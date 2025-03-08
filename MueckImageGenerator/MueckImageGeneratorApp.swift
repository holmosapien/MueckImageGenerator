//
//  MueckImageGeneratorApp.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 12/13/24.
//

import SwiftUI

@main
struct MueckImageGeneratorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(GlobalSettings.shared)
        }
        .commands {
            CommandGroup(before: .toolbar) {
                HiddenModelsToggleView(globalSettings: GlobalSettings.shared)
            }
        }
    }
}
