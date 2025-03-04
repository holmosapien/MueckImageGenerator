//
//  TensorArtCheckpointViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

extension TensorArtCheckpointView {
    @Observable
    class ViewModel {
        var checkpoint: TensorArtCheckpoint
        
        init(checkpoint: TensorArtCheckpoint) {
            self.checkpoint = checkpoint
        }
        
        func validateModelInput(settings: TensorArtSettings) async {
            checkpoint.name = nil
            
            if let modelId = parseTensorArtModel(checkpoint.modelInput) {
                do {
                    let modelResponse = try await fetchTensorArtModel(settings: settings, modelId: modelId, modelType: "CHECKPOINT")
                    
                    if let modelResponse = modelResponse {
                        checkpoint.modelInput = modelResponse.model.id
                        checkpoint.modelId = modelResponse.model.id
                        checkpoint.name = modelResponse.model.projectName
                    }
                } catch {
                    print("Error fetching model: \(error)")
                }
            }
        }
    }
}
