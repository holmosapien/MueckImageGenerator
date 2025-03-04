//
//  TensorArtJobModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 2/25/25.
//

import Foundation

@Observable
class TensorArtJob: Identifiable {
    let id: UUID = UUID()
    var jobId: String?
    var checkpoint: TensorArtCheckpoint = TensorArtCheckpoint()
    var loras: TensorArtLoraList = TensorArtLoraList()
    var sampler: String = "Euler a"
    var prompt: String = ""
    var width: Int = 1024
    var height: Int = 1152
    var seed: Int = -1
    var steps: Int = 20
    var configScale: Int = 5
    var clipSkip: Int = 1
    var guidance: Double = 3.5
}

@Observable
class TensorArtCheckpoint: Identifiable {
    let id: UUID = UUID()
    
    var modelInput: String = ""
    
    var modelId: String = "834401335727231078"
    var name: String?
}

@Observable
class TensorArtLoraList {
    var items: [TensorArtLora] = []
}

@Observable
class TensorArtLora: Identifiable {
    let id: UUID = UUID()
    
    var modelInput: String = ""
    var weightInput: String = ""
    
    var modelId: String = ""
    var name: String?
    var weight: Double = 1.0
}
