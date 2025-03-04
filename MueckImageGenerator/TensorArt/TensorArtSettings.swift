//
//  TensorArtSettings.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/2/25.
//

import SwiftUI

@Observable
class TensorArtSettings {
    var baseUrl: String {
        didSet { UserDefaults.standard.set(baseUrl, forKey: "tensorArtBaseUrl") }
    }
    
    var bearerToken: String {
        didSet { UserDefaults.standard.set(bearerToken, forKey: "tensorArtBearerToken") }
    }
    
    init() {
        self.baseUrl = UserDefaults.standard.string(forKey: "tensorArtBaseUrl") ?? "https://default-api-url.com"
        self.bearerToken = UserDefaults.standard.string(forKey: "tensorArtBearerToken") ?? ""
    }
}
