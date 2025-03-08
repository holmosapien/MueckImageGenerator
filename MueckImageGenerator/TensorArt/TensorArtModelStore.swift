//
//  TensorArtModelStore.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/4/25.
//

import SwiftUI

enum ModelType: String, Codable {
    case CHECKPOINT = "CHECKPOINT"
    case LORA = "LORA"
}

class TensorArtModelDefinition: Codable, Identifiable {
    let modelId: String
    let name: String
    let modelType: ModelType
    let hidden: Bool

    init(modelId: String, name: String, modelType: ModelType) {
        self.modelId = modelId
        self.name = name
        self.modelType = modelType
        self.hidden = false
    }
}

@Observable
class TensorArtModelStore {
    var models: [TensorArtModelDefinition] = []

    private static func filePath() throws -> URL {
        try FileManager.default.url(
            for: .documentDirectory,
            in: .userDomainMask,
            appropriateFor: nil,
            create: false
        )
        .appendingPathComponent("tensorArtModels.data")
    }

    func load() async throws {
        let task = Task<[TensorArtModelDefinition], Error> {
            let filePath = try Self.filePath()

            guard let data = try? Data(contentsOf: filePath) else {
                print("Unable to load models from \(filePath)")

                return []
            }

            let models = try JSONDecoder().decode([TensorArtModelDefinition].self, from: data)

            return models
        }

        let models = try await task.value

        self.models = models
    }

    func add(model: TensorArtModelDefinition) async throws {
        let task = Task {
            models.append(model)

            try await save()
        }

        _ = try await task.value
    }

    func save() async throws {
        let task = Task {
            print("Saving models to disk: \(models)")

            let filePath = try Self.filePath()
            let data = try JSONEncoder().encode(models)

            do {
                print("Saving models to \(filePath)")

                try data.write(to: filePath)
            } catch {
                print("Error saving models: \(error)")
            }
        }

        _ = try await task.value
    }
}
