//
//  TensorArtViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/28/25.
//

import SwiftUI

@Observable
class TensorArtJobConfig: Identifiable {
    let id: UUID = UUID()
    var jobId: String?
    var checkpoint: TensorArtCheckpoint = TensorArtCheckpoint()
    var loras: TensorArtLoraList = TensorArtLoraList()
    var sampler: String = "Euler a"
    var prompt: String = ""
    var width: CGFloat = 1024
    var height: CGFloat = 1152
    var seed: Int = -1
    var steps: Int = 20
    var configScale: Int = 5
    var clipSkip: Int = 1
    var guidance: Double = 3.5
}

@Observable
class TensorArtCheckpoint: Identifiable {
    let id: UUID = UUID()
    var modelId: String = "834401335727231078"
}

@Observable
class TensorArtLoraList {
    var items: [TensorArtLora] = []
}

@Observable
class TensorArtLora: Identifiable {
    let id: UUID = UUID()
    var modelId: String = ""
    var weight: Double = 1.0
}

@Observable
class GeneratedImage: Identifiable {
    let id: UUID = UUID()
    var imageId: String
    var seed: String
    var url: URL
    var rawImage: Data
    var nsImage: NSImage
    var localUrl: URL?

    init(imageId: String, seed: String, url: URL, rawImage: Data, nsImage: NSImage) {
        self.imageId = imageId
        self.seed = seed
        self.url = url
        self.rawImage = rawImage
        self.nsImage = nsImage
    }
}

extension TensorArtView {
    @Observable
    class ViewModel {
        var globalSettings: GlobalSettings
        var tensorArtSettings: TensorArtSettings

        var modelStore: TensorArtModelStore
        var generatedImageStore: GeneratedImageStore

        var jobConfig: TensorArtJobConfig
        var job: TensorArtJob?

        var checkpointViewModel: TensorArtModelPickerView.ViewModel
        var loraListViewModel: TensorArtLoraListView.ViewModel

        var showHiddenModels = false

        private var pollingTask: Task<Void, Never>?
        private var isPolling = false

        var canStartJob: Bool {
            if jobConfig.prompt.isEmpty {
                return false
            }

            if let job = self.job {
                if [.created, .pending, .queued, .running].contains(job.jobStatus) {
                    return false
                }
            }

            return true
        }

        var configWidth: CGFloat = 200
        var contentWidth: CGFloat = 600
        var contentHeight: CGFloat = 600
        var historyWidth: CGFloat = 200

        var previewDimensions: (width: CGFloat, height: CGFloat) = (width: 600, height: 600)

        var generatedImages: [GeneratedImage] = []

        init(
            globalSettings: GlobalSettings,
            tensorArtSettings: TensorArtSettings,
            modelStore: TensorArtModelStore = TensorArtModelStore(),
            generatedImageStore: GeneratedImageStore = GeneratedImageStore(),
            jobConfig: TensorArtJobConfig = TensorArtJobConfig()
        ) {
            print("Initializing TensorArt view model")

            self.globalSettings = globalSettings
            self.tensorArtSettings = tensorArtSettings

            self.modelStore = modelStore
            self.generatedImageStore = generatedImageStore

            self.jobConfig = jobConfig

            self.checkpointViewModel = TensorArtModelPickerView.ViewModel(store: modelStore, checkpoint: jobConfig.checkpoint)
            self.loraListViewModel = TensorArtLoraListView.ViewModel(store: modelStore, loras: jobConfig.loras)
        }

        func run() async {
            generatedImages.removeAll()

            do {
                let job = TensorArtJob(globalSettings: globalSettings, tensorArtSettings: tensorArtSettings)

                guard let jobId = try await job.start(jobConfig: jobConfig) else {
                    print("Failed to start job")

                    return
                }

                self.job = job
                self.previewDimensions = calculatePreviewDimensions(width: jobConfig.width, height: jobConfig.height)

                pollJob(jobId: jobId)
            } catch {
                print("Error starting job: \(error)")

                return
            }
        }

        func pollJob(jobId: String) {
            guard !isPolling else { return }

            isPolling = true

            pollingTask = Task {
                while isPolling {
                    print("Polling job status for job ID \(jobId)")

                    do {
                        guard let job = self.job else {
                            print("No job to poll")

                            isPolling = false

                            return
                        }

                        let jobSummary = try await job.getJob()

                        print("Job status: \(jobSummary.status)")

                        if jobSummary.status == .complete || jobSummary.status == .failed {
                            if jobSummary.status == .complete {
                                try await fetchImages(jobSummary: jobSummary)
                            }

                            isPolling = false

                            break
                        }

                        try await Task.sleep(for: .seconds(10))
                    } catch {
                        print("Error polling job status: \(error)")

                        isPolling = false
                    }
                }
            }
        }

        func fetchImages(jobSummary: JobSummary) async throws {
            for image in jobSummary.images {
                var request = URLRequest(url: image.url)

                request.httpMethod = "GET"

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

                    let generatedImage = GeneratedImage(
                        imageId: image.imageId,
                        seed: image.seed,
                        url: image.url,
                        rawImage: data,
                        nsImage: nsImage
                    )

                    generatedImages.append(generatedImage)
                } catch {
                    print("Error fetching image: \(error)")

                    return
                }
            }
        }

        func saveGeneratedImages() async throws {
            guard let job = job else {
                print("No job to save images")

                return
            }

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

            guard let jobId = job.jobId, let modelId = job.modelId, let prompt = job.prompt else {
                print("No job ID to save images")

                return
            }

            try await generatedImageStore.addGeneratedImages(
                jobId: jobId,
                modelId: modelId,
                prompt: prompt,
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

        func updateWindowDimensions(width: CGFloat, height: CGFloat) {
            configWidth = width * 0.2
            historyWidth = width * 0.2
            contentWidth = width - configWidth - historyWidth - 100
            contentHeight = height

            previewDimensions = calculatePreviewDimensions(width: contentWidth, height: contentHeight)
        }

        private func calculatePreviewDimensions(width: CGFloat, height: CGFloat) -> (width: CGFloat, height: CGFloat) {
            let aspectRatio: CGFloat = width / height

            var previewWidth: CGFloat = 600
            var previewHeight = previewWidth / aspectRatio

            if previewHeight > contentHeight {
                previewHeight = contentHeight
                previewWidth = previewHeight * aspectRatio
            }

            return (width: previewWidth, height: previewHeight)
        }

    }
}
