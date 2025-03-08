//
//  HiddenModelsToggleView.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/7/25.
//

import SwiftUI

struct HiddenModelsToggleView: View {
    @Bindable var globalSettings: GlobalSettings

    var body: some View {
        Toggle("Show Hidden Models", isOn: $globalSettings.showHiddenModels)
    }
}
