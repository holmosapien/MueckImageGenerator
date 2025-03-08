//
//  GeneratedImageStore.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/7/25.
//

import SwiftUI

class GeneratedImageData: Codable, Identifiable {
    class GeneratedImage: Codable, Identifiable {
        var jobId: String
        var imageId: String
        var modelId: String
        var loraIds: [String]
        var prompt: String
        var seed: String
        var imageUrl: String
        var localPath: String

        init(
            jobId: String,
            imageId: String,
            modelId: String,
            loraIds: [String],
            prompt: String,
            seed: String,
            imageUrl: String,
            localPath: String
        ) {
            self.jobId = jobId
            self.imageId = imageId
            self.modelId = modelId
            self.loraIds = loraIds
            self.prompt = prompt
            self.seed = seed
            self.imageUrl = imageUrl
            self.localPath = localPath
        }
    }

    var localImagePath: String
    var generatedImages: [GeneratedImage]

    init(localImagePath: String, generatedImages: [GeneratedImage]) {
        self.localImagePath = localImagePath
        self.generatedImages = generatedImages
    }
}

@Observable
class GeneratedImageStore {
    var localImagePath: Data?
    var generatedImages: [GeneratedImageData.GeneratedImage] = []

    private static func filePath() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent("generatedImages.data")
    }

    func load() async throws {
        let task = Task<GeneratedImageData?, Error> {
            let filePath = try Self.filePath()

            guard let data = try? Data(contentsOf: filePath) else {
                print("Unable to load generated images from \(filePath)")

                return nil
            }

            let imageData = try JSONDecoder().decode(GeneratedImageData.self, from: data)

            return imageData
        }

        if let imageData = try await task.value {
            self.localImagePath = Data(base64Encoded: imageData.localImagePath)
            self.generatedImages = imageData.generatedImages
        }
    }

    func setLocalImagePath(path: URL) async throws {
        let bookmark = try path.bookmarkData(
            options: .withSecurityScope,
            includingResourceValuesForKeys: nil,
            relativeTo: nil
        )

        localImagePath = bookmark

        try await save()
    }

    func addGeneratedImages(
        jobId: String,
        modelId: String,
        prompt: String,
        images: [JobImage]
    ) async throws {
        for image in images {
            if let localUrl = image.localUrl {
                let localPath = localUrl.absoluteString

                let generatedImage = GeneratedImageData.GeneratedImage(
                    jobId: jobId,
                    imageId: image.imageId,
                    modelId: modelId,
                    loraIds: [],
                    prompt: prompt,
                    seed: image.seed,
                    imageUrl: image.imageUrl.absoluteString,
                    localPath: localPath
                )

                generatedImages.append(generatedImage)
            }
        }

        try await save()
    }

    func save() async throws {
        var bookmark: String

        if let localImagePath = localImagePath {
            bookmark = localImagePath.base64EncodedString()
        } else {
            print("No local image path to save")

            return
        }

        Task {
            let imageData = GeneratedImageData(
                localImagePath: bookmark,
                generatedImages: generatedImages
            )

            let data = try JSONEncoder().encode(imageData)

            let filePath = try Self.filePath()

            do {
                print("Saving generated images to \(filePath)")

                try data.write(to: filePath)
            } catch {
                print("Error saving generated images: \(error)")
            }
        }
    }
}
