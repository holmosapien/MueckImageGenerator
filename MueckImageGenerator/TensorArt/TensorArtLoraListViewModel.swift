//
//  TensorArtLoraListViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

extension TensorArtLoraListView {
    @Observable
    class ViewModel {
        var store: TensorArtModelStore
        var loras: TensorArtLoraList

        var loraListViewModelMap: [UUID: TensorArtLoraListItemView.ViewModel] = [:]

        init(store: TensorArtModelStore, loras: TensorArtLoraList) {
            print("Initializing LoRA list view with LoRAs: \(loras)")

            self.store = store
            self.loras = loras

            for lora in loras.items {
                loraListViewModelMap[lora.id] = TensorArtLoraListItemView.ViewModel(
                    store: store,
                    lora: lora
                )
            }
        }

        func addLora() {
            let lora = TensorArtLora()

            loras.items.append(lora)

            let viewModel = TensorArtLoraListItemView.ViewModel(
                store: store,
                lora: lora
            )

            loraListViewModelMap[lora.id] = viewModel

            print("LoRA list: \(loras)")
        }

        func removeLora(lora: TensorArtLora) {
            if let index = loras.items.firstIndex(where: { $0.id == lora.id }) {
                loras.items.remove(at: index)
            }

            loraListViewModelMap.removeValue(forKey: lora.id)
        }
    }
}
