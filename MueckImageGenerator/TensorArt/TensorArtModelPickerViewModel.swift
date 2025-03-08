//
//  TensorArtModelPickerViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/4/25.
//

import SwiftUI

let NO_MODEL_UUID = "F1140F6E-DEF1-4054-8FF6-F219BDB25DB4"
let NEW_MODEL_UUID = "D9ECBF86-D891-48CA-91FD-83C0233A7672"

struct ModelResponse: Codable {
    struct ModelDetails: Codable {
        var id: String
        var name: String
        var modelType: String
        var projectName: String
    }

    var model: ModelDetails
}

extension TensorArtModelPickerView {
    @Observable
    class ViewModel {
        var store: TensorArtModelStore
        var modelType: ModelType

        var checkpoint: TensorArtCheckpoint?
        var lora: TensorArtLora?

        var models: [TensorArtModelDefinition] {
            return store.models.filter{ $0.modelType.rawValue == self.modelType.rawValue }.sorted{ $0.name < $1.name }
        }

        var selectedModel: String = NO_MODEL_UUID
        var showNewModelSheet = false
        var newModelInput: String = ""

        init(store: TensorArtModelStore, checkpoint: TensorArtCheckpoint) {
            print("Initializing checkpoint picker: \(store.models)")

            self.store = store
            self.modelType = ModelType.CHECKPOINT
            self.checkpoint = checkpoint
        }

        init(store: TensorArtModelStore, lora: TensorArtLora) {
            print("Initializing LoRA picker: \(store.models)")

            self.store = store
            self.modelType = ModelType.LORA
            self.lora = lora
        }

        func loadModels() async {
            do {
                try await store.load()

                print("Loaded models: \(models)")
            } catch {
                print("Error loading models: \(error)")
            }
        }

        func validateModelInput(settings: TensorArtSettings) async {
            if let modelId = parseTensorArtModel(newModelInput) {
                do {
                    let modelResponse = try await fetchTensorArtModel(settings: settings, modelId: modelId, modelType: modelType)

                    if let modelResponse = modelResponse {
                        selectedModel = modelResponse.model.id

                        let newModel = TensorArtModelDefinition(
                            modelId: modelResponse.model.id,
                            name: modelResponse.model.projectName,
                            modelType: modelType
                        )

                        try await store.add(model: newModel)

                        showNewModelSheet = false
                    }
                } catch {
                    print("Error fetching model: \(error)")
                }
            }
        }

        private func parseTensorArtModel(_ input: String) -> String? {

            //
            // The input can either be:
            //
            // 1. A model ID (string of integers)
            // 2. A URL in the format https://tensor.art/models/757279507095956705(\/.+)?$
            //
            // In either case we want to use a regular expression to extract the model ID.
            //

            let modelId: String

            let modelIdPattern = #"^\d+$"#
            let urlPattern = #"^https://tensor.art/models/(\d+)(\/.+)?$"#

            let modelIdRegex = try! NSRegularExpression(pattern: modelIdPattern, options: [])
            let urlRegex = try! NSRegularExpression(pattern: urlPattern, options: [])

            if modelIdRegex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.count)) != nil {
                modelId = input
            } else if let match = urlRegex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.count)) {
                let range = match.range(at: 1)

                modelId = (input as NSString).substring(with: range)
            } else {
                return nil
            }

            return modelId
        }

        private func fetchTensorArtModel(settings: TensorArtSettings, modelId: String, modelType: ModelType) async throws -> ModelResponse? {
            guard let url = URL(string: "\(settings.baseUrl)/v1/models/\(modelId)") else {
                return nil
            }

            print("Fetching model from \(url)")

            var request = URLRequest(url: url)

            request.httpMethod = "GET"
            request.setValue("Bearer \(settings.bearerToken)", forHTTPHeaderField: "Authorization")

            let (data, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                throw URLError(.badServerResponse) // 🚨 Handle non-200 responses
            }

            let modelResponse = try JSONDecoder().decode(ModelResponse.self, from: data)

            if modelResponse.model.modelType != modelType.rawValue {
                return nil
            }

            return modelResponse
        }

        func updateJobModel(modelId: String) {
            if (modelType == ModelType.CHECKPOINT) {
                checkpoint?.modelId = modelId

                print("Updated checkpoint model: \(checkpoint)")
            } else {
                lora?.modelId = modelId

                print("Updated LoRA model: \(lora)")
            }
        }
    }
}
