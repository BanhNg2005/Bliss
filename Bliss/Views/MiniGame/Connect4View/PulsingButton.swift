//
//  PulsingButton.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI

struct PulsingButton: View {
    @State private var expand = false
        let tileState: TileState
        let action: () -> Void
        private let animations = TileAnimations()

        var body: some View {
            Button(action: {
                withAnimation(self.animations.dropAnimation) {
                    self.action()
                }
            }) {
                RoundTile(state: tileState)
            }
            .scaleEffect(expand ? 0.85 : 1.0)
            .animation(animations.pulseAnimation).onAppear {
                self.expand.toggle()
            }
        }
}
