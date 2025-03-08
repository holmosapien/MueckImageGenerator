//
//  TensorAertLoraListItemViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

extension TensorArtLoraListItemView {
    @Observable
    class ViewModel: Identifiable {
        var store: TensorArtModelStore
        var lora: TensorArtLora
        var weight: String = "1.0"

        var loraItemViewModel: TensorArtModelPickerView.ViewModel

        init(store: TensorArtModelStore, lora: TensorArtLora) {
            print("Initializing LoRA list item view model with LoRA: \(lora)")

            self.store = store
            self.lora = lora

            self.loraItemViewModel = TensorArtModelPickerView.ViewModel(
                store: store,
                lora: lora
            )
        }

        func updateWeight() {
            // Try to convert the string into a double and place it into the weight property.

            if let doubleWeight = Double(weight) {
                lora.weight = doubleWeight
            }
        }
    }
}
