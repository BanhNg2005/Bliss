//
//  GameState.swift
//  Bliss
//
//  Created by Bu on 30/3/26.
//

import Foundation

enum GameState: Equatable {

    case playerOneTurn
    case playerTwoTurn
    case gameOver(GameResult)

    var currentTile: TileState {
        switch self {
        case .playerOneTurn:
            return .playerOne
        case .playerTwoTurn:
            return .playerTwo
        default:
            return .vacant
        }
    }

    func nextTurn() -> GameState {
        switch self {
        case .playerOneTurn:
            return .playerTwoTurn
        case .playerTwoTurn:
            return .playerOneTurn
        default:
            fatalError("Something went wrong game is over")
        }
    }
}
