//
//  ContentView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 12/13/24.
//

import SwiftUI

struct ContentView: View {
    @State private var tensorArtSettings = TensorArtSettings()
    
    var body: some View {
        TensorArtView()
            .environment(tensorArtSettings)
    }
}

#Preview {
    ContentView()
}
