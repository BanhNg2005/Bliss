//
//  RootView.swift
//  Bliss
//
//  Created by Bu on 31/3/26.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var viewModel: BoardViewModel
    @State private var showGameOverAlert = false
        
    var gameResult: GameResult? {
        if case GameState.gameOver(let result) = viewModel.state {
            return result
        }
        return nil
    }

    var body: some View {
        ZStack() {
            config.backgroundImage
                .resizable()
                .ignoresSafeArea()
                .shadow(color: config.primaryColor, radius: 50)
            TransparentBoard()
                .environmentObject(viewModel)
                .onChange(of: viewModel.state) { oldValue, newValue in
                    if case GameState.gameOver = newValue {
                        showGameOverAlert = true
                    }
                }
        }
        .navigationTitle("Connect 4")
        .navigationBarTitleDisplayMode(.inline)
        .alert(gameResult?.title ?? "", isPresented: $showGameOverAlert) {
            Button("Play Again") {
                self.viewModel.resetGame()
            }
        } message: {
            Text("")
        }
    }
}

