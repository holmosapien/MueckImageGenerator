//
//  TensorAertLoraListItemViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

struct ModelResponse: Codable {
    var model: ModelDetails
}

struct ModelDetails: Codable {
    var id: String
    var name: String
    var modelType: String
    var projectName: String
}

extension TensorArtLoraListItemView {
    @Observable
    class ViewModel {
        var lora: TensorArtLora
        
        init(lora: TensorArtLora) {
            self.lora = lora
        }
        
        func processInput(settings: TensorArtSettings) async {
            if let modelId = parseTensorArtModel(lora.modelInput) {
                do {
                    let modelResponse = try await fetchTensorArtModel(settings: settings, modelId: modelId, modelType: "LORA")
                    
                    if let modelResponse = modelResponse {
                        lora.modelId = modelResponse.model.id
                        lora.name = modelResponse.model.projectName
                        lora.weight = Double(lora.weightInput) ?? 1.0
                    }
                } catch {
                    print("Error fetching model: \(error)")
                }
            }
        }
    }
}
