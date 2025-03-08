//
//  TensorArtViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/28/25.
//

import SwiftUI

struct JobRequest: Encodable {
    struct AnyJobStage: Encodable {
        private let encodeClosure: (Encoder) throws -> Void

        init<T: Encodable>(_ value: T) {
            encodeClosure = { encoder in
                try value.encode(to: encoder)
            }
        }

        func encode(to encoder: Encoder) throws {
            try encodeClosure(encoder)
        }
    }

    protocol JobStage: Encodable {}

    struct InputInitializationStageRequest: JobStage {
        var type: String = "INPUT_INITIALIZE"
        var inputInitialize: InputInitializationStageDetails
    }

    struct InputInitializationStageDetails: Encodable {
        var count: Int
        var seed: Int
    }

    struct DiffusionStageRequest: Encodable {
        var type: String = "DIFFUSION"
        var diffusion: DiffusionStageDetails
    }

    struct DiffusionStageDetails: Encodable {
        var cfgScale: Int
        var clipSkip: Int
        var guidance: Double
        var height: Int
        var prompts: [TensorArtJobPrompt]
        var sampler: String
        var sdVae: String
        var sdModel: String
        var steps: Int
        var width: Int

        enum CodingKeys: String, CodingKey {
            case cfgScale = "cfgScale"
            case clipSkip = "clipSkip"
            case guidance = "guidance"
            case height = "height"
            case prompts = "prompts"
            case sampler = "sampler"
            case sdVae = "sdVae"
            case sdModel = "sd_model"
            case steps = "steps"
            case width = "width"
        }
    }

    struct TensorArtJobPrompt: Encodable {
        var text: String
    }

    var requestId: UUID
    var stages: [AnyJobStage]

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case stages = "stages"
    }
}

struct JobResponse: Codable {
    struct JobDetails: Codable {
        enum JobStatus: String, Codable {
            case CREATED = "CREATED"
            case WAITING = "WAITING"
            case RUNNING = "RUNNING"
            case SUCCESS = "SUCCESS"
        }

        struct JobWaitingInfo: Codable {
            var queuePosition: String?
            var queueLength: String?

            enum CodingKeys: String, CodingKey {
                case queuePosition = "queueRank"
                case queueLength = "queueLen"
            }
        }

        struct JobSuccessInfo: Codable {
            var images: [JobImageDetails]
            var imageExifMetaMap: [String: JobImageMetadata]
        }

        struct JobImageDetails: Codable {
            var id: String
            var url: String
        }

        struct JobImageMetadata: Codable {
            var meta: JobImageMetadataDetails
        }

        struct JobImageMetadataDetails: Codable {
            var fileSize: String
            var imageSize: String
            var mimeType: String
            var seed: String

            enum CodingKeys: String, CodingKey {
                case fileSize = "FileSize"
                case imageSize = "ImageSize"
                case mimeType = "MIMEType"
                case seed = "Seed"
            }
        }

        var id: String
        var status: JobStatus
        var credits: Decimal?
        var waitingInfo: JobWaitingInfo?
        var successInfo: JobSuccessInfo?
    }

    var job: JobDetails
}

enum JobStatus: String {
    case none = "none"
    case created = "created"
    case queued = "queued"
    case running = "running"
    case complete = "complete"
    case failed = "failed"
}

class JobImage {
    var imageId: String
    var seed: String
    var rawImage: Data
    var nsImage: NSImage
    var imageUrl: URL
    var localUrl: URL?

    init(imageId: String, seed: String, rawImage: Data, nsImage: NSImage, imageUrl: URL) {
        self.imageId = imageId
        self.seed = seed
        self.rawImage = rawImage
        self.nsImage = nsImage
        self.imageUrl = imageUrl
    }
}

extension TensorArtView {
    @Observable
    class ViewModel {
        var globalSettings: GlobalSettings
        var tensorArtSettings: TensorArtSettings

        var job: TensorArtJob
        var modelStore: TensorArtModelStore
        var generatedImageStore: GeneratedImageStore

        var checkpointViewModel: TensorArtModelPickerView.ViewModel
        var loraListViewModel: TensorArtLoraListView.ViewModel

        var showHiddenModels = false

        var jobStatus: JobStatus = .none

        private var pollingTask: Task<Void, Never>?
        var isPolling = false

        var canStartJob: Bool {
            if isPolling || job.checkpoint.modelId.isEmpty || job.prompt.isEmpty {
                return false
            }

            return true
        }

        var generatedImages: [JobImage] = []

        init(
            globalSettings: GlobalSettings,
            tensorArtSettings: TensorArtSettings,
            job: TensorArtJob = TensorArtJob(),
            modelStore: TensorArtModelStore = TensorArtModelStore(),
            generatedImageStore: GeneratedImageStore = GeneratedImageStore()
        ) {
            print("Initializing TensorArt view model")

            self.globalSettings = globalSettings
            self.tensorArtSettings = tensorArtSettings

            self.job = job
            self.modelStore = modelStore
            self.generatedImageStore = generatedImageStore

            self.checkpointViewModel = TensorArtModelPickerView.ViewModel(store: modelStore, checkpoint: job.checkpoint)
            self.loraListViewModel = TensorArtLoraListView.ViewModel(store: modelStore, loras: job.loras)
        }

        func run() async {
            generatedImages = []
            jobStatus = .created

            do {
                if let jobId = try await startJob() {
                    job.jobId = jobId

                    pollJob(jobId: jobId)
                } else {
                    jobStatus = .failed
                }
            } catch {
                print("Error starting job: \(error)")

                jobStatus = .failed
            }
        }

        private func startJob() async throws -> String? {
            let tensorArtJob = JobRequest(
                requestId: UUID(),
                stages: [
                    JobRequest.AnyJobStage(JobRequest.InputInitializationStageRequest(
                        inputInitialize: JobRequest.InputInitializationStageDetails(
                            count: 1,
                            seed: -1
                        )
                    )),
                    JobRequest.AnyJobStage(JobRequest.DiffusionStageRequest(
                        diffusion: JobRequest.DiffusionStageDetails(
                            cfgScale: job.configScale,
                            clipSkip: job.clipSkip,
                            guidance: job.guidance,
                            height: job.height,
                            prompts: [JobRequest.TensorArtJobPrompt(text: job.prompt)],
                            sampler: job.sampler,
                            sdVae: "Automatic",
                            sdModel: job.checkpoint.modelId,
                            steps: job.steps,
                            width: job.width
                        )
                    ))
                ]
            )

            guard let url = URL(string: "\(tensorArtSettings.baseUrl)/v1/jobs") else {
                print("Invalid URL")

                return nil
            }

            print("URL: \(url)")

            var request = URLRequest(url: url)

            request.httpMethod = "POST"

            let encoder = JSONEncoder()

            request.setValue("Bearer \(tensorArtSettings.bearerToken)", forHTTPHeaderField: "Authorization")
            request.httpBody = try encoder.encode(tensorArtJob)

            do {
                let encodedRequestBody = try encoder.encode(tensorArtJob)

                print("Encoded request body: \(String(data: encodedRequestBody, encoding: .utf8)!)")
            } catch {
                print("Error encoding request body: \(error)")
            }

            var jobResponse: JobResponse

            do {
                let (data, response) = try await URLSession.shared.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }

                jobResponse = try JSONDecoder().decode(JobResponse.self, from: data)
            } catch {
                print("Error starting job: \(error)")

                throw error
            }

            print("Started job with ID \(jobResponse.job.id)")

            job.jobId = jobResponse.job.id

            return jobResponse.job.id
        }

        private func pollJob(jobId: String) {
            guard !isPolling else { return }

            isPolling = true

            pollingTask = Task {
                while isPolling {
                    print("Polling job status for job ID \(jobId)")

                    do {
                        let jobResponse = try await getJob(jobId: jobId)
                        let status = getJobStatus(jobResponse: jobResponse)

                        print("Job status: \(status)")

                        jobStatus = status

                        if status == .complete || status == .failed {
                            isPolling = false

                            fetchImages(jobResponse: jobResponse)

                            break
                        }

                        try await Task.sleep(for: .seconds(10))
                    } catch {
                        print("Error polling job status: \(error)")

                        isPolling = false

                        self.jobStatus = .failed
                    }
                }
            }
        }

        private func getJob(jobId: String) async throws -> JobResponse {
            guard let url = URL(string: "\(tensorArtSettings.baseUrl)/v1/jobs/\(jobId)") else {
                throw URLError(.badURL)
            }

            var request = URLRequest(url: url)

            request.httpMethod = "GET"
            request.setValue("Bearer \(tensorArtSettings.bearerToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let jobResponse = try JSONDecoder().decode(JobResponse.self, from: data)

            return jobResponse
        }

        private func getJobStatus(jobId: String) async throws -> JobStatus {
            let job = try await getJob(jobId: jobId)

            return getJobStatus(jobResponse: job)
        }

        private func getJobStatus(jobResponse: JobResponse) -> JobStatus {
            switch jobResponse.job.status {
            case JobResponse.JobDetails.JobStatus.CREATED:
                return .created
            case JobResponse.JobDetails.JobStatus.WAITING:
                return .queued
            case JobResponse.JobDetails.JobStatus.RUNNING:
                return .running
            case JobResponse.JobDetails.JobStatus.SUCCESS:
                return .complete
            }
        }

        private func fetchImages(jobResponse: JobResponse) {
            guard let successInfo = jobResponse.job.successInfo else {
                return
            }

            for image in successInfo.images {
                guard let url = URL(string: image.url) else {
                    print("Invalid image URL")

                    continue
                }

                var request = URLRequest(url: url)

                request.httpMethod = "GET"

                Task {
                    do {
                        let (data, response) = try await URLSession.shared.data(for: request)

                        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                            print("Error fetching image: \(response)")

                            return
                        }

                        guard let nsImage = NSImage(data: data) else {
                            print("Failed to create NSImage")

                            return
                        }

                        var seed: String = ""

                        if let metadata = successInfo.imageExifMetaMap[image.id] {
                            seed = metadata.meta.seed
                        }

                        let jobImage = JobImage(
                            imageId: image.id,
                            seed: seed,
                            rawImage: data,
                            nsImage: nsImage,
                            imageUrl: url
                        )

                        generatedImages.append(jobImage)
                    } catch {
                        print("Error fetching image: \(error)")
                    }
                }
            }
        }

        func saveGeneratedImages() async throws {
            var localImagePath: URL?

            // First see if we already have a bookmark saved.
            // If we do and it's stale, we'll clear it and re-prompt the user.

            if let bookmark = generatedImageStore.localImagePath {
                var stale: Bool = false

                localImagePath = try URL(
                    resolvingBookmarkData: bookmark,
                    options: .withSecurityScope,
                    relativeTo: nil,
                    bookmarkDataIsStale: &stale
                )

                if stale {
                    localImagePath = nil
                }
            }

            // If we don't have a bookmark, as the user to select their save location.

            if localImagePath == nil {
                if let path = await askLocalImagePath() {
                    try await generatedImageStore.setLocalImagePath(path: path)

                    if let bookmark = generatedImageStore.localImagePath {
                        var stale: Bool = false

                        localImagePath = try URL(
                            resolvingBookmarkData: bookmark,
                            options: .withSecurityScope,
                            relativeTo: nil,
                            bookmarkDataIsStale: &stale
                        )

                        // We'll skip checking if it's stale as we just set it.
                    }
                } else {
                    print("User aborted selecting image path.")

                    return
                }
            }

            // Now we can tell the sandbox we're ready to save some images.

            if let path = localImagePath {
                let usable = path.startAccessingSecurityScopedResource()

                if !usable {
                    print("Unable to access local image path")

                    localImagePath = nil
                }
            }

            if localImagePath == nil {
                print("No local image path to save")

                return
            }

            for image in generatedImages {
                let imageId = image.imageId
                let rawImage = image.rawImage

                if let path = localImagePath {
                    let filePath = path.appendingPathComponent("\(imageId).png")

                    do {
                        try rawImage.write(to: filePath)

                        print("Saved image to \(filePath)")
                    } catch {
                        print("Error saving image: \(error)")
                    }

                    image.localUrl = filePath
                }
            }

            guard let jobId = job.jobId else {
                print("No job ID to save images")

                return
            }

            try await generatedImageStore.addGeneratedImages(
                jobId: jobId,
                modelId: job.checkpoint.modelId,
                prompt: job.prompt,
                images: generatedImages
            )
        }

        @MainActor
        private func askLocalImagePath() -> URL? {
            let panel = NSOpenPanel()

            panel.title = "Select a folder to save images"
            panel.canChooseFiles = false
            panel.canChooseDirectories = true
            panel.allowsMultipleSelection = false

            return panel.runModal() == .OK ? panel.url : nil
        }
    }
}
