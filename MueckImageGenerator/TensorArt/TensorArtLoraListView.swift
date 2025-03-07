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
        VStack(alignment: .leading) {
            ForEach(viewModel.loras.items) { lora in
                HStack {
                    if let loraItemViewModel = viewModel.loraListViewModelMap[lora.id] {
                        TensorArtLoraListItemView(viewModel: loraItemViewModel)

                        Button(action: { viewModel.removeLora(lora: lora) }) {
                            Image(systemName: "minus.circle")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            Button(action: viewModel.addLora) {
                Label("Add LoRA", systemImage: "plus.circle")
            }
        }
    }
}

struct TensorArtLoraListItemView: View {
    @Bindable var viewModel: ViewModel

    @Environment(TensorArtSettings.self) private var settings

    var body: some View {
        TensorArtModelPickerView(viewModel: viewModel.loraItemViewModel)

        TextField("Weight", text: $viewModel.weight)
            .labelsHidden()
            .containerRelativeFrame(.horizontal, count: 100, span: 20, spacing: 0)
            .onChange(of: viewModel.weight) { oldValue, newValue in
                viewModel.updateWeight()
            }
    }
}
