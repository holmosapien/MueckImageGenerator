//
//  LoraView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/25/25.
//

import SwiftUI

struct TensorArtLoraListView: View {
    @Bindable var viewModel: ViewModel

    var body: some View {
        Section(header: Text("LoRAs")) {
            ForEach(self.viewModel.loras.items) { lora in
                TensorArtLoraListItemView(viewModel: TensorArtLoraListItemView.ViewModel(lora: lora))
            }
            Button("Add Lora") {
                self.viewModel.addLora()
            }
        }
    }
}

struct TensorArtLoraListItemView: View {
    @Bindable var viewModel: ViewModel
    @Environment(TensorArtSettings.self) private var settings
    
    var body: some View {
        HStack {
            if (viewModel.lora.name == nil) {
                TextField("Model ID", text: $viewModel.lora.modelInput)
                TextField("Weight", text: $viewModel.lora.weightInput)
                
                Button(action: {
                    Task {
                        await viewModel.processInput(settings: settings)
                    }
                }) {
                    HStack {
                        Text("Save LoRA")
                    }
                }
            } else {
                let loraName: String = viewModel.lora.name ?? "Unknown"
                let loraWeight: String = String(viewModel.lora.weight)
                
                Text(loraName)
                Text(loraWeight)
            }
        }
    }
}
