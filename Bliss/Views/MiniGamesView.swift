import SwiftUI

struct MiniGamesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 36))
            Text("Mini Games")
                .font(.title2.weight(.semibold))
            // put a list of games here, have a AirHockey already
            List {
                NavigationLink(destination: AirHockey()) {
                    Text("Air Hockey")
                }
                NavigationLink(destination: SpaceInvader()) {
                    Text("Space Invader")
                }
                NavigationLink(destination: TicTacToe()) {
                    Text("Tic Tac Toe")
                }
                .listRowInsets(EdgeInsets())
                .padding(.vertical, 8)
            }
        }
        .padding(24)
        .navigationTitle("Mini Games")
    }
}

#Preview {
    NavigationStack {
        MiniGamesView()
    }
}
