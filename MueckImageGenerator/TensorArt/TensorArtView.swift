//
//  TensorArtView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

struct TensorArtView: View {
    @State private var viewModel = ViewModel()
    
    @State private var selectedImage: String? // The generated image
    @State private var showDrawer = false // Controls the right-side drawer
    @State private var selectedFavorite: String? // Selected favorite
    @State private var formParameters = TensorArtJob() // Current form parameters
    @State private var favorites: [String: TensorArtJob] = [:] // Stored favorite parameter sets
    @State private var generatedImages: [String] = [] // List of previously generated images
    
    @Environment(TensorArtSettings.self) private var settings
    
    var body: some View {
        HStack {
            VStack {
                ZStack {
                    if let selectedImage = selectedImage {
                        Image(systemName: selectedImage)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 300)
                            .border(Color.gray, width: 1)
                    } else {
                        Text("No Image Generated")
                            .frame(height: 300)
                            .border(Color.gray, width: 1)
                    }
                }
                .padding()

                HStack {
                    Picker("Favorites", selection: $selectedFavorite) {
                        Text("Select Favorite").tag(nil as String?)
                        ForEach(favorites.keys.sorted(), id: \.self) { key in
                            Text(key).tag(key as String?)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())

                    Button("Save Favorite") {
                        let newFavorite = "Favorite \(favorites.count + 1)"
                        favorites[newFavorite] = formParameters
                    }
                }
                .padding()

                Form {
                    @Bindable var settings = settings
                    
                    TextField("Base URL", text: $settings.baseUrl)
                    SecureField("Bearer Token", text: $settings.bearerToken)
                    
                    TensorArtCheckpointView(viewModel: viewModel.checkpointViewModel)
                    TensorArtLoraListView(viewModel: viewModel.loraListViewModel)
                    
                    TextField("Prompt", text: $viewModel.job.prompt)
                    
                    Button(action: { viewModel.run(settings: settings) }) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Start Job")
                        }
                    }
                }
                .padding()
            }

            if showDrawer {
                Divider()
                ScrollView {
                    VStack {
                        Text("Previous Images")
                            .font(.headline)
                            .padding()
                        
                        ForEach(generatedImages, id: \.self) { image in
                            Image(systemName: image)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 100)
                                .border(Color.gray, width: 1)
                                .padding(4)
                        }
                    }
                }
                .frame(width: 200)
            }

            // Toggle Drawer Button
            Button(action: {
                showDrawer.toggle()
            }) {
                Image(systemName: showDrawer ? "chevron.right" : "chevron.left")
                    .padding()
            }
        }
    }
}
