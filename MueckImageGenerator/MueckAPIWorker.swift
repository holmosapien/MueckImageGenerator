//
//  MueckPlaygroundDelegate.swift
//  MueckImageGenerator
//
//  Created by Dan Holm on 12/13/24.
//

import Foundation
import ImagePlayground

let TEST_PROMPTS = [
    "A giant teacup floating on a serene lake under a starry sky, with tiny fairies using it as a boat, glowing softly in the moonlight, fantasy art style, vibrant colors",
    "A city made entirely of candy, with gumdrop houses, chocolate rivers, and lollipop trees, inhabited by cheerful gummy bear citizens, sunny afternoon, playful mood",
    "A steampunk owl wearing intricate golden goggles, perched on a mechanical tree branch, surrounded by glowing gears and steam clouds, high-detail illustration",
    "A whimsical hot air balloon shaped like a giant jellyfish, glowing with neon colors, floating over a surreal coral reef city, underwater fantasy world",
    "A group of tiny penguins in tuxedos hosting an elegant tea party on an iceberg, with a polar bear waiter serving pastries, detailed and humorous illustration",
    "A library inside a massive tree, with glowing bookshelves filled with floating books, a cozy fireplace, and a cat librarian wearing glasses, enchanting and warm atmosphere",
    "A dragon made entirely of flowers, flying gracefully over a meadow, petals scattering in the breeze, pastel colors, soft and dreamy style",
    "A surreal castle floating in the clouds, with waterfalls cascading into the sky, surrounded by flying whales and colorful hot air balloons, ethereal and magical",
    "A whimsical marketplace run by talking animals, with a fox selling potions, a raccoon juggling fruit, and a wise owl reading fortunes, colorful and lively illustration",
    "An enchanted forest where the trees have glowing eyes and friendly faces, a glowing path leading to a mysterious crystal cave, magical and immersive"
]

struct MueckRequest {
    var prompt: String
}

@MainActor
class MueckAPIWorker: ObservableObject {
    private var timer: Timer?
    private var taskWorker: Task<Void, Never>?
    
    @Published var concept: ImagePlaygroundConcept?
    
    init(interval: UInt32) {
        initializeWorker(interval: interval)
    }

    func initializeWorker(interval: UInt32) {
        taskWorker = Task {
            while true {
                print("Sleeping for \(interval) seconds ...")
                
                try? await Task.sleep(for: .seconds(interval))
                
                print("Done sleeping.")
                
                await processNextRequest()
            }
        }
    }
    
    func processNextRequest() async -> Void {
        if self.concept != nil {
            print("There is already an active task running.")
            
            return
        }
        
        print("Fetching request ...")
        
        let request = await fetchRequest()
        
        self.concept = ImagePlaygroundConcept.extracted(from: request.prompt)
        
        print("Returning prompt \"\(request.prompt)\" ...")
    }
    
    private func fetchRequest() async -> MueckRequest {
        let prompt = TEST_PROMPTS.randomElement()!
        let request = MueckRequest(prompt: prompt)
        
        return request
    }
}
