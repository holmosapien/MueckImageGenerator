//
//  GlobalSettings.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/7/25.
//

import SwiftUI

import SwiftUI

@Observable
class GlobalSettings {
    static let shared = GlobalSettings()

    var showHiddenModels: Bool = false
}
