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
        
        for col in 0..<cols {
            var column = [Tile]()
            for row in 0..<rows {
                column.append(Tile(col: col, row: row, state: .vacant, id: UUID()))
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
        var result = [Tile]()
        let slope = diagnol.highSlope
        
        var startCol = col
        var startRow = row
        while startCol - slope.0 >= 0, startCol - slope.0 < cols, startRow - slope.1 >= 0, startRow - slope.1 < rows {
            startCol -= slope.0
            startRow -= slope.1
        }
        
        var currCol = startCol
        var currRow = startRow
        while currCol >= 0, currCol < cols, currRow >= 0, currRow < rows {
            result.append(tiles[currCol][currRow])
            currCol += slope.0
            currRow += slope.1
        }
        return result
    }
    
    /// Add a tile to the board for column index. Will optionally return the new tile if the column is not full
        /// - Parameter col: The column index for dropped tile
        /// - Parameter state: The state of the new tile
        @discardableResult
        mutating func addTile(inColumn col: Int, forState state: TileState) -> Tile? {
            if let emptyRow = tilesFor(column: col).filter({ $0.state == .vacant}).first?.row {
                let tile = Tile(col: col, row: emptyRow, state: state, id: UUID())
                tiles[col][emptyRow] = tile
                return tile
            }
            return nil
        }
    

}
