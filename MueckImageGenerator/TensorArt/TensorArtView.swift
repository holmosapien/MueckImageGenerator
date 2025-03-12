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
    @State private var formParameters = TensorArtJobConfig() // Current form parameters
    @State private var favorites: [String: TensorArtJobConfig] = [:] // Stored favorite parameter sets

    @State private var generatedImages: [String] = [] // Generated images

    var body: some View {
        GeometryReader { geometry in
            let totalWidth = geometry.size.width
            let totalHeight = geometry.size.height

            NavigationSplitView {
                VStack {
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
                            TextEditor(text: $viewModel.jobConfig.prompt)
                                .frame(height: 10 * 20)
                                .scrollDisabled(true)
                                .font(.system(size: 14))
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

                                if viewModel.generatedImages.count > 0 {
                                    Button(action: {
                                        Task {
                                            try await viewModel.saveGeneratedImages()
                                        }
                                    }) {
                                        Text("Save Images")
                                    }
                                }

                                if let job = viewModel.job, let jobId = job.jobId {
                                    Text("Job ID: \(jobId), Status: \(job.jobStatus)")
                                }
                            }
                        }

                        Spacer()
                    }
                }
                .frame(width: viewModel.configWidth)
                .padding(.all, 20)
            } content: {
                Section {
                    if (viewModel.generatedImages.count == 0) {
                        Text("No Image Generated")
                            .frame(width: viewModel.previewDimensions.width, height: viewModel.previewDimensions.height)
                            .border(Color.gray, width: 1)
                    } else {
                        TabView(selection: $currentImageIndex) {
                            ForEach(viewModel.generatedImages) { image in
                                Image(nsImage: image.nsImage)
                                    .resizable()
                                    .frame(width: viewModel.previewDimensions.width, height: viewModel.previewDimensions.height)
                                    .tag(image.imageId)
                                    .tabItem {
                                        Text("Image")
                                    }
                            }
                        }
                        .tabViewStyle(.automatic)
                    }
                }
                .frame(width: viewModel.contentWidth)
            } detail: {
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
                .frame(width: viewModel.historyWidth)
            }
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

                viewModel.updateWindowDimensions(width: totalWidth, height: totalHeight)
            }
            .onChange(of: totalWidth) { oldWidth, newWidth in
                viewModel.updateWindowDimensions(width: totalWidth, height: totalHeight)
            }
            .onChange(of: totalHeight) { oldHeight, newHeight in
                viewModel.updateWindowDimensions(width: totalWidth, height: totalHeight)
            }
        }
    }
}
