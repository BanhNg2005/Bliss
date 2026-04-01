//
//  DroppingTile.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI

struct DroppingTile: View {
    @State private var dropped = false
    let tileState: TileState
    let distance: CGFloat
    private let tileAnimations = TileAnimations()
    
    var body: some View {
        ZStack {
            RoundTile(state: tileState)
                .offset(x: 0, y: dropped ? 0 : -distance)
                .onAppear {
                    withAnimation(tileAnimations.dropAnimation) {
                        self.dropped = true
                    }
                }
            RoundTile(state: .vacant)
        }
    }
}
