//
//  Connect4Tile.swift
//  Bliss
//
//  Created by Bu on 30/3/26.
//

import Foundation

struct Tile: Identifiable {
    let col: Int
    let row: Int
    var state: TileState
    var id: UUID()
}
