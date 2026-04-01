//
//  ConnectFour.swift
//  Bliss
//
//  Created by Bu on 27/3/26.
//

import SwiftUI

struct ConnectFour: View {
    @StateObject private var viewModel = BoardViewModel(board: Board(cols: config.columns, rows: config.rows), tilesToWin: config.tilesToWin)
    
    var body: some View {
        RootView()
            .environmentObject(viewModel)
    }
}

#Preview {
    ConnectFour()
}
