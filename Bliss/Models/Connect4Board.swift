//
//  Connect4Board.swift
//  Bliss
//
//  Created by Bu on 30/3/26.
//

import Foundation

struct Board {
    enum Diagnol {
        case ascending
        case descending
        
        var highSlope: (Int, Int) {
            switch self {
            case .ascending: return (1, 1)
            case .descending: return (-1, 1)
            }
        }
        
        var lowSlope: (Int, Int) {
            switch self {
            case .ascending: return (-1, -1)
            case .descending: return (1, -1)
            }
        }
    }
    
    private(set) var tiles = [[Tile]]()
    private let cols: Int
    private let rows: Int
    
    init(cols: Int, rows: Int) {
        
        self.cols = cols
        self.rows = rows
        
//        for column in 0..<columns {
//            var c = [Tile]()
//            for row in 0..<rows {
//                c.append(Tile(column: column, row: row, state: .vacant))
//            }
//            tiles.append(c)
//        }
        for col in 0..<cols {
            var column = [Tile]()
            for row in 0..<rows {
                column.append(Tile(col: col, row: row, state: .vacant))
            }
            tiles.append(column)
        }
    }
    
    var tileCount: Int {
        return cols * rows
    }

    var columnCount: Int {
        return cols
    }

    func tilesFor(row: Int) -> [Tile] {
        (0..<tiles.count).map({ tiles[$0][row] })
    }

    func tilesFor(column: Int) -> [Tile] {
        tiles[column]
    }
    
    func tilesFor(diagnol: Diagnol, at col: Int, row: Int) -> [Tile] {
        let tile = tiles[col][row]
        let highTiles = adjacentDiagnols(column: col, row: row, colIncrement: diagnol.highSlope.0, rowIncrement: diagnol.highSlope.1) ?? [Tile]()
        let lowTiles = adjacentDiagnols(column: col, row: row, colIncrement: diagnol.lowSlope.0, rowIncrement: diagnol.lowSlope.1) ?? [Tile]()
        return lowTiles + [tile] + highTiles
    }
    
    /// Add a tile to the board for column index. Will optionally return the new tile if the column is not full
        /// - Parameter column: The column index for dropped tile
        /// - Parameter state: The state of the new tile
        @discardableResult
        mutating func addTile(inColumn column: Int, forState state: TileState) -> Tile? {
            if let emptyRow = tilesFor(column: column).filter({ $0.state == .vacant}).first?.row {
                let tile = Tile(column: column, row: emptyRow, state: state)
                tiles[column][emptyRow] = tile
                return tile
            }
            return nil
        }
    

}

extension Board {
    /// Optionally returns three successive tiles from any coordinate in any slope direction. If adjacent coordinate is out of bounds nil is returned
    /// - Parameter column: The column index for the tile
    /// - Parameter row: The row index for the tile
    /// - Parameter colIncrement: The y slope of the diagnol
    /// - Parameter rowIncrement: The x slope of the diagnol
    private func adjacentDiagnols(column: Int, row: Int, colIncrement: Int, rowIncrement: Int) -> [Tile]? {
        guard
            row + (rowIncrement * (rows / 2)) >= 0,
            row + (rowIncrement * (rows / 2)) < tiles[0].count,
            column + (colIncrement * (cols / 2)) >= 0,
            column + (colIncrement * (cols / 2)) < tiles.count
        else {
            return nil
        }
        return [
            tiles[column + colIncrement][row + rowIncrement],
            tiles[column + (colIncrement * 2)][row + (rowIncrement * 2)],
            tiles[column + (colIncrement * 3)][row + (rowIncrement * 3)]
        ]
    }
}
