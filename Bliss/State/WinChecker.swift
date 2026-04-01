//
//  WinChecker.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import Foundation

/// A Type that checks whether the game is concluded for the `winningTile`, `board`,  and `moveCount` once a new move has been made
struct WinChecker {

    let board: Board
    let winningTile: Tile
    let moveCount: Int
    let tilesToWin: Int
    var result: GameResult? {
        return checkEndGame()
    }
    
    /// Checks for all possible horizontal, vertical and diagnol wins. Returns `.inProgress` if win or draw are not reached
    private func checkEndGame() -> GameResult? {
        let horizontals = board.tilesFor(row: winningTile.row)
        let verticals = board.tilesFor(column: winningTile.col)
        let diagonalsAscending = board.tilesFor(diagnol: .ascending, at: winningTile.col, row: winningTile.row)
        let diagonalsDescending = board.tilesFor(diagnol: .descending, at: winningTile.col, row: winningTile.row)
        if winningTiles(horizontals) || winningTiles(verticals) || winningTiles(diagonalsAscending) || winningTiles(diagonalsDescending) {
             return .win(winningTile.state)
        }
        if moveCount == board.tileCount {
            return .draw
        }
        return nil
    }
    
    /// Checks for four consecutive tiles matching `winningTile`
    /// - Parameter tiles: The possible winning tiles
    private func winningTiles(_ tiles: [Tile]) -> Bool {
        guard tiles.count >= tilesToWin else { return false }
        var count = 0
        var isWin = false
        tiles.forEach { (t) in
            count = t.state == winningTile.state ? count + 1 : 0
            if count == tilesToWin {
                isWin = true
            }
        }
        return isWin
    }
}

