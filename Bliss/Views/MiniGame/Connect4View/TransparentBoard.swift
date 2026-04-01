//
//  TransparentBoard.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI

struct TransparentBoard: View {
    @EnvironmentObject var viewModel: BoardViewModel

        var body: some View {
            HStack {
                ForEach(0..<viewModel.board.columnCount) { columnIdx in
                    VStack {
                        PulsingButton(tileState: self.viewModel.state.currentTile) {
                            self.viewModel.dropTile(inColumn: columnIdx)
                        }
                        Column(tiles: self.viewModel.tilesAt(index: columnIdx))
                    }
                }
            }.background(Color.clear)
                .padding()
                .aspectRatio(1, contentMode: .fit)
        }
}

#Preview {
    TransparentBoard()
}
