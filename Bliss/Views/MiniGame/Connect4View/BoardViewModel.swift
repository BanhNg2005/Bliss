//
//  BoardViewModel.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI
import Combine

final class BoardViewModel: ObservableObject {
    
    @Published var board: Board
    private let tilesToWin: Int
    private var moveCount = 0
    var state: GameState = .playerOneTurn
    
    init(board: Board, tilesToWin: Int) {
        self.board = board
        self.tilesToWin = tilesToWin
    }
    
    func tilesAt(index: Int) -> [Tile] {
        board.tilesFor(column: index).reversed()
    }
    
    func dropTile(inColumn column: Int) {
        if let tile = board.addTile(inColumn: column, forState: state.currentTile) {
            moveCount += 1
            updateState(newTile: tile)
        }
    }

    private func updateState(newTile: Tile) {
        let winCheckResult = WinChecker(board: board, winningTile: newTile, moveCount: moveCount, tilesToWin: tilesToWin).result
        switch winCheckResult {
        case .win(let tileState):
            state = .gameOver(.win(tileState))
        case .draw:
            state = .gameOver(.draw)
        case .none:
            state = state.nextTurn()
        }
    }
}

extension BoardViewModel {
    func resetGame() {
//        board = Board(cols: config.columns, rows: config.rows)
        board = Board(cols: board.columnCount, rows: board.tilesFor(row: 0).count)
        state = .playerOneTurn
        moveCount = 0
    }
}
