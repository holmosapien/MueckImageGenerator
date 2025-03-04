//
//  TensorArtUtils.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/2/25.
//

import Foundation

func parseTensorArtModel(_ input: String) -> String? {
    
    //
    // The input can either be:
    //
    // 1. A model ID (string of integers)
    // 2. A URL in the format https://tensor.art/models/757279507095956705(\/.+)?$
    //
    // In either case we want to use a regular expression to extract the model ID.
    //
    
    let modelId: String
    
    let modelIdPattern = #"^\d+$"#
    let urlPattern = #"^https://tensor.art/models/(\d+)(\/.+)?$"#
    
    let modelIdRegex = try! NSRegularExpression(pattern: modelIdPattern, options: [])
    let urlRegex = try! NSRegularExpression(pattern: urlPattern, options: [])
    
    if modelIdRegex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.count)) != nil {
        modelId = input
    } else if let match = urlRegex.firstMatch(in: input, options: [], range: NSRange(location: 0, length: input.count)) {
        let range = match.range(at: 1)
        
        modelId = (input as NSString).substring(with: range)
    } else {
        return nil
    }
    
    return modelId
}

func fetchTensorArtModel(settings: TensorArtSettings, modelId: String, modelType: String) async throws -> ModelResponse? {
    guard let url = URL(string: "\(settings.baseUrl)/v1/models/\(modelId)") else {
        return nil
    }
    
    print("Fetching model from \(url)")
    
    var request = URLRequest(url: url)
    
    request.httpMethod = "GET"
    request.setValue("Bearer \(settings.bearerToken)", forHTTPHeaderField: "Authorization")
    
    let (data, response) = try await URLSession.shared.data(for: request)
    
    guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
        throw URLError(.badServerResponse) // 🚨 Handle non-200 responses
    }
    
    let modelResponse = try JSONDecoder().decode(ModelResponse.self, from: data)
    
    if modelResponse.model.modelType != modelType {
        return nil
    }
    
    return modelResponse
}
