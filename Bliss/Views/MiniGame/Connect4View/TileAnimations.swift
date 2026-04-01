//
//  TileAnimations.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI

struct TileAnimations {
    var pulseAnimation: Animation {
        Animation
            .easeInOut
            .speed(0.5)
            .delay(0.1)
            .repeatForever(autoreverses: true)
    }
    
    var dropAnimation: Animation {
        Animation
            .easeIn(duration: 0.6)
            .speed(1.5)
            .repeatCount(1)
    }
}
