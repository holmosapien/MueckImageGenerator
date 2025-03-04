//
//  TensorArtLoraListViewModel.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 3/1/25.
//

import SwiftUI

extension TensorArtLoraListView {
    @Observable
    class ViewModel {
        var loras: TensorArtLoraList
        
        init(loras: TensorArtLoraList) {
            self.loras = loras
        }
        
        func addLora() {
            loras.items.append(TensorArtLora())
            
            print("LoRA list: \(loras)")
        }
    }
}
