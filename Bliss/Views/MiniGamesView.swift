import SwiftUI

struct MiniGamesView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 36))
                .foregroundColor(.blue)
                .padding(.top, 10)
            Text("Mini Games")
                .font(.title2.weight(.semibold))
            
            List {
                NavigationLink(destination: AirHockey()) {
                    HStack(spacing: 16) {
                        Image(systemName: "hockey.puck.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                        Text("Air Hockey")
                            .font(.headline)
                    }
                }
                .padding(.vertical, 8)
                
                NavigationLink(destination: SpaceInvader()) {
                    HStack(spacing: 16) {
                        Image(systemName: "airplane")
                            .font(.title2)
                            .foregroundColor(.red)
                        Text("Space Invader")
                            .font(.headline)
                    }
                }
                .padding(.vertical, 8)
                
                NavigationLink(destination: TicTacToe()) {
                    HStack(spacing: 16) {
                        Image(systemName: "number.square")
                            .font(.title2)
                            .foregroundColor(.green)
                        Text("Tic Tac Toe")
                            .font(.headline)
                    }
                }
                .padding(.vertical, 8)
                
                NavigationLink(destination: ConnectFour()) {
                    HStack(spacing: 16) {
                        Image(systemName: "circle.grid.cross")
                            .font(.title2)
                            .foregroundColor(.orange)
                        Text("Connect 4")
                            .font(.headline)
                    }
                }
                .padding(.vertical, 8)
            }
            .listStyle(InsetGroupedListStyle())
        }
        .navigationTitle("Mini Games")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        MiniGamesView()
    }
}
