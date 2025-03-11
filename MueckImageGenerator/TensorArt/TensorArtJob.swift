//
//  TensorArtJobModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/25/25.
//

import SwiftUI

struct TensorArtJobRequest: Encodable {
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

struct TensorArtJobResponse: Codable {
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

class JobSummary {
    var jobId: String
    var modelId: String
    var prompt: String
    var status: JobStatus
    var images: [JobImage]

    init(jobId: String, modelId: String, prompt: String, status: JobStatus, images: [JobImage]) {
        self.jobId = jobId
        self.modelId = modelId
        self.prompt = prompt
        self.status = status
        self.images = images
    }
}

enum JobStatus: String {
    case none = "none"
    case created = "created"
    case queued = "queued"
    case running = "running"
    case complete = "complete"
    case failed = "failed"
}

class JobImage: Identifiable {
    let id = UUID()
    var imageId: String
    var seed: String
    var url: URL

    init(imageId: String, seed: String, url: URL) {
        self.imageId = imageId
        self.seed = seed
        self.url = url
    }
}

enum TensorArtJobError: Error {
    case missingJobId
}

class TensorArtJob {
    private var globalSettings: GlobalSettings
    private var tensorArtSettings: TensorArtSettings

    var jobId: String?
    var jobStatus: JobStatus = .none
    var modelId: String?
    var prompt: String?
    var images: [JobImage] = []

    init(globalSettings: GlobalSettings, tensorArtSettings: TensorArtSettings) {
        self.globalSettings = globalSettings
        self.tensorArtSettings = tensorArtSettings
    }

    func start(jobConfig: TensorArtJobConfig) async throws -> String? {
        modelId = jobConfig.checkpoint.modelId
        prompt = jobConfig.prompt

        let tensorArtJob = TensorArtJobRequest(
            requestId: UUID(),
            stages: [
                TensorArtJobRequest.AnyJobStage(TensorArtJobRequest.InputInitializationStageRequest(
                    inputInitialize: TensorArtJobRequest.InputInitializationStageDetails(
                        count: 1,
                        seed: -1
                    )
                )),
                TensorArtJobRequest.AnyJobStage(TensorArtJobRequest.DiffusionStageRequest(
                    diffusion: TensorArtJobRequest.DiffusionStageDetails(
                        cfgScale: jobConfig.configScale,
                        clipSkip: jobConfig.clipSkip,
                        guidance: jobConfig.guidance,
                        height: jobConfig.height,
                        prompts: [TensorArtJobRequest.TensorArtJobPrompt(text: jobConfig.prompt)],
                        sampler: jobConfig.sampler,
                        sdVae: "Automatic",
                        sdModel: jobConfig.checkpoint.modelId,
                        steps: jobConfig.steps,
                        width: jobConfig.width
                    )
                ))
            ]
        )

        guard let url = URL(string: "\(tensorArtSettings.baseUrl)/v1/jobs") else {
            print("Invalid URL")

            return nil
        }

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

        do {
            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse)
            }

            let jobResponse = try JSONDecoder().decode(TensorArtJobResponse.self, from: data)

            jobId = jobResponse.job.id
        } catch {
            print("Error starting job: \(error)")

            throw error
        }

        return jobId
    }

    func getJob() async throws -> JobSummary {
        guard let jobId = jobId else {
            throw TensorArtJobError.missingJobId
        }

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

        let rawJobResponse = try JSONDecoder().decode(TensorArtJobResponse.self, from: data)

        let status = parseJobStatus(jobResponse: rawJobResponse)
        let images = parseJobImages(jobResponse: rawJobResponse)

        let jobResponse = JobSummary(
            jobId: rawJobResponse.job.id,
            modelId: modelId ?? "",
            prompt: prompt ?? "",
            status: status,
            images: images
        )

        return jobResponse
    }

    private func parseJobStatus(jobResponse: TensorArtJobResponse) -> JobStatus {
        switch jobResponse.job.status {
        case TensorArtJobResponse.JobDetails.JobStatus.CREATED:
            return .created
        case TensorArtJobResponse.JobDetails.JobStatus.WAITING:
            return .queued
        case TensorArtJobResponse.JobDetails.JobStatus.RUNNING:
            return .running
        case TensorArtJobResponse.JobDetails.JobStatus.SUCCESS:
            return .complete
        }
    }

    private func parseJobImages(jobResponse: TensorArtJobResponse) -> [JobImage] {
        guard let successInfo = jobResponse.job.successInfo else {
            return []
        }

        var images: [JobImage] = []

        for image in successInfo.images {
            guard let url = URL(string: image.url) else {
                print("Invalid image URL")

                continue
            }

            var seed: String = ""

            if let metadata = successInfo.imageExifMetaMap[image.id] {
                seed = metadata.meta.seed
            }

            let jobImage = JobImage(
                imageId: image.id,
                seed: seed,
                url: url
            )

            images.append(jobImage)
        }

        return images
    }
}
