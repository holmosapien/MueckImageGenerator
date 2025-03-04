//
//  ModelView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/25/25.
//

import SwiftUI

struct TensorArtCheckpointView: View {
    @Bindable var viewModel: ViewModel
    
    @Environment(TensorArtSettings.self) private var settings
    
    var body: some View {
        if let checkpointName = viewModel.checkpoint.name {
            Text(checkpointName)
                .font(.system(size: 8))
        }
        
        TextField("Model ID", text: $viewModel.checkpoint.modelInput)
            .disableAutocorrection(true)
            .onSubmit {
                Task {
                    await viewModel.validateModelInput(settings: settings)
                }
            }
    }
}
