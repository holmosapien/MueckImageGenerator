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
    var model: ModelDetails
}

struct ModelDetails: Codable {
    var id: String
    var name: String
    var modelType: String
    var projectName: String
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
            print("Initializing lora picker: \(store.models)")

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
