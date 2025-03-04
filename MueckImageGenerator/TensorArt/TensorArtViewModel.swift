//
//  TensorArtViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/28/25.
//

import SwiftUI

extension TensorArtView {
    @Observable
    class ViewModel {
        var job = TensorArtJob()
        
        var checkpointViewModel: TensorArtCheckpointView.ViewModel {
            TensorArtCheckpointView.ViewModel(checkpoint: job.checkpoint)
        }
        
        var loraListViewModel: TensorArtLoraListView.ViewModel {
            TensorArtLoraListView.ViewModel(loras: job.loras)
        }
        
        func run(settings: TensorArtSettings) {
            print("Base URL: \(settings.baseUrl)")
            print("Bearer Token: \(settings.bearerToken)")
            
            for lora in job.loras.items {
                print("LoRA: \(lora.id)")
            }
        }
    }
}
