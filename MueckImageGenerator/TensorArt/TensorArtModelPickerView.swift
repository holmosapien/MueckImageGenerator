//
//  TensorArtModelPickerView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/4/25.
//

import SwiftUI

public struct TensorArtModelPickerView: View {
    @Bindable var viewModel: ViewModel

    @Environment(TensorArtSettings.self) private var settings

    public var body: some View {
        Picker("Select a model", selection: $viewModel.selectedModel) {
            Text("Select a model...").tag(NO_MODEL_UUID)
            ForEach(viewModel.models) { model in
                Text(model.name).tag(model.modelId)
            }
            Divider()
            Text("Add a new model...").tag(NEW_MODEL_UUID)
        }
        .labelsHidden()
        .onChange(of: viewModel.selectedModel) { oldValue, newValue in
            if newValue == NEW_MODEL_UUID {
                viewModel.showNewModelSheet.toggle()
            } else if (newValue != NO_MODEL_UUID) {
                viewModel.updateJobModel(modelId: newValue)
            }
        }
        .sheet(isPresented: $viewModel.showNewModelSheet) {
            print("Show new model sheet: \(viewModel.showNewModelSheet)")
            print("Models: \(viewModel.store.models)")
        } content: {
            VStack {
                Text("Enter a TensorArt model ID or URL")
                TextField("Model ID:", text: $viewModel.newModelInput)
                    .disableAutocorrection(true)
                    .onSubmit {
                        Task {
                            await viewModel.validateModelInput(settings: settings)
                        }
                    }
            }
        }
    }
}
