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
        var job: TensorArtJob
        var modelStore = TensorArtModelStore()

        var checkpointViewModel: TensorArtModelPickerView.ViewModel
        var loraListViewModel: TensorArtLoraListView.ViewModel

        init(job: TensorArtJob = TensorArtJob(), store: TensorArtModelStore = TensorArtModelStore()) {
            self.job = job
            self.modelStore = store

            self.checkpointViewModel = TensorArtModelPickerView.ViewModel(store: store, checkpoint: job.checkpoint)
            self.loraListViewModel = TensorArtLoraListView.ViewModel(store: store, loras: job.loras)
        }

        func run(settings: TensorArtSettings) {
            print("Base URL: \(settings.baseUrl)")
            print("Bearer Token: \(settings.bearerToken)")
            print("Model ID: \(job.checkpoint.modelId)")

            for lora in job.loras.items {
                print("LoRA: \(lora.modelId) @ \(lora.weight)")
            }
        }
    }
}
