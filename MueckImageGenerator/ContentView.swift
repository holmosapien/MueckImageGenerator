//
//  ContentView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 12/13/24.
//

import SwiftUI

struct ContentView: View {
    @Environment(GlobalSettings.self) var globalSettings

    @State private var viewModel: TensorArtView.ViewModel?
    @State private var tensorArtSettings = TensorArtSettings()

    var body: some View {
        if let viewModel = viewModel {
            TensorArtView(viewModel: viewModel)
                .environment(tensorArtSettings)
        } else {
            ProgressView("Loading...")
                .onAppear {
                    viewModel = TensorArtView.ViewModel(
                        globalSettings: globalSettings,
                        tensorArtSettings: tensorArtSettings
                    )
                }
        }
    }
}

#Preview {
    ContentView()
}
