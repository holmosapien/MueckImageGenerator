//
//  TensorArtView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

struct TensorArtView: View {
    @Bindable var viewModel: ViewModel

    @State private var currentImageIndex: Int = 0

    @State private var selectedFavorite: String? // Selected favorite
    @State private var formParameters = TensorArtJob() // Current form parameters
    @State private var favorites: [String: TensorArtJob] = [:] // Stored favorite parameter sets

    @State private var showDrawer = false // Controls the right-side drawer
    @State private var generatedImages: [String] = [] // Generated images

    var body: some View {
        HStack {
            VStack {
                ZStack {
                    if (viewModel.generatedImages.count == 0) {
                        Text("No Image Generated")
                            .frame(width: 600, height: 600)
                            .border(Color.gray, width: 1)
                    } else {
                        TabView(selection: $currentImageIndex) {
                            ForEach(viewModel.generatedImages.indices, id: \.self) { index in
                                Image(nsImage: viewModel.generatedImages[index].nsImage)
                                    .resizable()
                                    .frame(width: 600, height: 600)
                                    .tag(index)
                                    .tabItem {
                                        Text("Image \(index + 1)")
                                    }
                            }
                        }
                        .tabViewStyle(.automatic)
                    }
                }
                .padding()

                Form {
                    LabeledContent("Base URL") {
                        TextField("Base URL", text: $viewModel.tensorArtSettings.baseUrl)
                            .labelsHidden()
                    }

                    LabeledContent("Bearer Token") {
                        SecureField("Bearer Token", text: $viewModel.tensorArtSettings.bearerToken)
                            .labelsHidden()
                    }

                    Divider()

                    LabeledContent("Favorites") {
                        HStack {
                            Picker("Favorites", selection: $selectedFavorite) {
                                Text("Select Favorite").tag(nil as String?)
                                ForEach(favorites.keys.sorted(), id: \.self) { key in
                                    Text(key).tag(key as String?)
                                }
                            }
                            .labelsHidden()
                            .pickerStyle(MenuPickerStyle())

                            Button("Save Favorite") {
                                let newFavorite = "Favorite \(favorites.count + 1)"
                                favorites[newFavorite] = formParameters
                            }
                        }
                    }

                    LabeledContent("Model") {
                        TensorArtModelPickerView(viewModel: viewModel.checkpointViewModel)
                    }

                    LabeledContent("LoRAs") {
                        TensorArtLoraListView(viewModel: viewModel.loraListViewModel)
                    }

                    Divider()

                    LabeledContent("Prompt") {
                        TextEditor(text: $viewModel.job.prompt)
                            .scrollDisabled(true)
                    }

                    LabeledContent("") {
                        HStack {
                            Button(action: {
                                Task {
                                    await viewModel.run()
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus")
                                    Text("Start Job")
                                }
                            }
                            .disabled(!viewModel.canStartJob)

                            if (viewModel.generatedImages.count > 0) {
                                Button(action: {
                                    Task {
                                        try await viewModel.saveGeneratedImages()
                                    }
                                }) {
                                    Text("Save Images")
                                }
                            }

                            Text("Show Hidden Models: \(viewModel.globalSettings.showHiddenModels)")
                        }
                    }
                }
                .padding()
                .onAppear {
                    Task {
                        print("Loading ...")

                        do {
                            try await viewModel.modelStore.load()
                        } catch {
                            print("Error loading models: \(error)")
                        }

                        do {
                            try await viewModel.generatedImageStore.load()
                        } catch {
                            print("Error loading generated images: \(error)")
                        }
                    }
                }
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
                                .frame(height: 50)
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
