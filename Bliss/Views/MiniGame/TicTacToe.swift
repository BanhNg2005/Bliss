//
//  TicTacToe.swift
//  Bliss
//
//  Created by Bu on 27/3/26.
//

import SwiftUI

enum Turn {
    case Nought, Cross
    
    var symbol: String {
        switch self {
        case .Nought: return "O"
        case .Cross: return "X"
        }
    }
}

struct TicTacToe: View {
    @State private var board: [String] = Array(repeating: "", count: 9)
    @State private var currentTurn: Turn = .Cross
    @State private var firstTurn: Turn = .Cross
    
    @State private var crossScore = 0
    @State private var noughtScore = 0
    
    @State private var alertTitle = ""
    @State private var showAlert = false
    
    var body: some View {
        VStack {
            Spacer()
            
            Text("Turn")
                .font(.title2)
                .bold()
            
            Text(currentTurn.symbol)
                .font(.system(size: 80, weight: .black))
                .padding(.top, 5)
            
            Spacer()
            
            ZStack {
                // The Grid Lines
                VStack(spacing: 0) {
                    Spacer()
                    Rectangle().frame(height: 6).foregroundColor(.black)
                    Spacer()
                    Rectangle().frame(height: 6).foregroundColor(.black)
                    Spacer()
                }
                
                HStack(spacing: 0) {
                    Spacer()
                    Rectangle().frame(width: 6).foregroundColor(.black)
                    Spacer()
                    Rectangle().frame(width: 6).foregroundColor(.black)
                    Spacer()
                }
                
                // The Buttons
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 3), spacing: 0) {
                    ForEach(0..<9, id: \.self) { index in
                        Button(action: {
                            boardTapAction(index: index)
                        }) {
                            Text(board[index])
                                .font(.system(size: 70, weight: .regular))
                                .foregroundColor(.black)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                        }
                        .disabled(board[index] != "" || showAlert)
                    }
                }
            }
            .frame(width: 300, height: 300)
            
            Spacer()
            
            VStack(spacing: 15) {
                Text("Total Wins")
                    .font(.title2)
                    .bold()
                
                Text("X Wins : \(crossScore)")
                    .font(.title3)
                
                Text("O Wins : \(noughtScore)")
                    .font(.title3)
            }
            
            Spacer()
        }
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text("O Wins: \(noughtScore)\nX Wins: \(crossScore)"),
                dismissButton: .default(Text("Reset Board")) {
                    resetBoard()
                }
            )
        }
    }
    
    // MARK: - Game Logic
    
    func boardTapAction(index: Int) {
        if board[index] == "" {
            board[index] = currentTurn.symbol
            
            if checkForVictory(symbol: "X") {
                crossScore += 1
                resultAlert(title: "Cross Wins!")
            } else if checkForVictory(symbol: "O") {
                noughtScore += 1
                resultAlert(title: "Nought Wins!")
            } else if fullBoard() {
                resultAlert(title: "Draw")
            } else {
                currentTurn = currentTurn == .Cross ? .Nought : .Cross
            }
        }
    }
    
    func resultAlert(title: String) {
        alertTitle = title
        showAlert = true
    }
    
    func resetBoard() {
        board = Array(repeating: "", count: 9)
        if firstTurn == .Nought {
            firstTurn = .Cross
        } else {
            firstTurn = .Nought
        }
        currentTurn = firstTurn
    }
    
    func checkForVictory(symbol s: String) -> Bool {
        // Horizontal
        if thisSymbol(0, s) && thisSymbol(1, s) && thisSymbol(2, s) { return true }
        if thisSymbol(3, s) && thisSymbol(4, s) && thisSymbol(5, s) { return true }
        if thisSymbol(6, s) && thisSymbol(7, s) && thisSymbol(8, s) { return true }
        // Vertical
        if thisSymbol(0, s) && thisSymbol(3, s) && thisSymbol(6, s) { return true }
        if thisSymbol(1, s) && thisSymbol(4, s) && thisSymbol(7, s) { return true }
        if thisSymbol(2, s) && thisSymbol(5, s) && thisSymbol(8, s) { return true }
        // Diagonal
        if thisSymbol(0, s) && thisSymbol(4, s) && thisSymbol(8, s) { return true }
        if thisSymbol(2, s) && thisSymbol(4, s) && thisSymbol(6, s) { return true }
        return false
    }
    
    func thisSymbol(_ index: Int, _ symbol: String) -> Bool {
        return board[index] == symbol
    }
    
    func fullBoard() -> Bool {
        return !board.contains("")
    }
}


#Preview {
    TicTacToe()
}
