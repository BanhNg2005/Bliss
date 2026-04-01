//
//  RoundTile.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI

struct RoundTile: View {
    @State private var expand = true
    let state: TileState
    var primaryColor: Color = .primary
    var secondaryColor: Color = .secondary
    private let animations = TileAnimations()
    
    private var shouldAnimate: Bool {
        return state != .vacant && expand
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(state.color)
            Circle()
                .stroke(primaryColor, lineWidth: 3)
            state.image
                .foregroundColor(secondaryColor)
        }
        .scaleEffect(shouldAnimate ? 1.5: 1.0)
        .opacity(shouldAnimate ? 0.1 : 1.0)
        // Use .animation on the view to animate changes to dependent state
        .animation(animations.dropAnimation, value: shouldAnimate)
        .onAppear {
            if self.shouldAnimate {
                // If you must trigger it on appear, use withAnimation here
                withAnimation(animations.dropAnimation) {
                    self.expand = false
                }
            }
        }
    }
}
