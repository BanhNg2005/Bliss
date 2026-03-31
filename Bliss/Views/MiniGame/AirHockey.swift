import SwiftUI
import Combine

struct AirHockey: View {
    // MARK: - Game State
    @State private var puckPosition = CGPoint(x: 200, y: 400)
    @State private var puckVelocity = CGVector(dx: 0, dy: 0)
    
    @State private var player1MalletPosition = CGPoint(x: 200, y: 600)
    @State private var player2MalletPosition = CGPoint(x: 200, y: 200)
    
    @State private var player1Score = 0
    @State private var player2Score = 0
    
    // MARK: - Animation State
    @State private var isGoal: Bool = false
    @State private var gradientOffset: CGFloat = -1.0
    
    @State private var gameOver: Bool = false
    @State private var winnerMessage: String = ""
    
    // MARK: - Constants
    let puckRadius: CGFloat = 20
    let malletRadius: CGFloat = 35
    let goalWidth: CGFloat = 120
    let aiSpeed: CGFloat = 4.5
    let friction: CGFloat = 0.992 // Simulates air table friction
    let maxSpeed: CGFloat = 25.0
    
    // 60 FPS Game Loop
    let timer = Timer.publish(every: 1/60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            
            ZStack {
                // MARK: - Table Background & Markings
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.black.opacity(0.8))
                
                // Center Line
                Rectangle()
                    .fill(Color.cyan.opacity(0.5))
                    .frame(height: 4)
                    .position(x: size.width / 2, y: size.height / 2)
                
                // Center Circle
                Circle()
                    .stroke(Color.cyan.opacity(0.5), lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .position(x: size.width / 2, y: size.height / 2)
                
                // Table Border
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.cyan.opacity(isGoal ? 1 : 0.4), lineWidth: 6)
                    .shadow(color: .cyan.opacity(isGoal ? 0.8 : 0.3), radius: isGoal ? 20 : 5)
                
                // MARK: - Scoreboard
                VStack {
                    Text("\(player2Score)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.red.opacity(0.3))
                        .rotationEffect(.degrees(180))
                        .padding(.top, 40)
                    
                    Spacer()
                    
                    Text("\(player1Score)")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.blue.opacity(0.3))
                        .padding(.bottom, 40)
                }
                
                // MARK: - Goal Animation Layer
                if isGoal {
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .cyan.opacity(0.0),
                            .cyan.opacity(0.3),
                            .purple.opacity(0.4),
                            .blue.opacity(0.3),
                            .cyan.opacity(0.0)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .scaleEffect(1.5)
                    .opacity(0.7)
                    .blur(radius: 50)
                    .offset(x: size.width * gradientOffset, y: 0)
                }

                // MARK: - Game Objects
                // Puck
                Circle()
                    .fill(Color.white)
                    .frame(width: puckRadius * 2, height: puckRadius * 2)
                    .shadow(color: .white.opacity(0.5), radius: 5)
                    .position(puckPosition)
                
                // Player 1 (Bottom - Blue)
                Circle()
                    .fill(Color.blue)
                    .frame(width: malletRadius * 2, height: malletRadius * 2)
                    .shadow(color: .blue, radius: 10)
                    .position(player1MalletPosition)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                // Keep player on their half of the table
                                var newPos = value.location
                                newPos.x = max(malletRadius, min(size.width - malletRadius, newPos.x))
                                newPos.y = max(size.height / 2 + malletRadius, min(size.height - malletRadius, newPos.y))
                                player1MalletPosition = newPos
                            }
                    )
                
                // Player 2 AI (Top - Red)
                Circle()
                    .fill(Color.red)
                    .frame(width: malletRadius * 2, height: malletRadius * 2)
                    .shadow(color: .red, radius: 10)
                    .position(player2MalletPosition)
                
            }
            .onReceive(timer) { _ in
                guard !isGoal && !gameOver else { return } // Pause gameplay during goal animation or game over
                updatePuck(in: size)
                moveAI(in: size)
                detectCollisions(in: size)
                checkGoals(in: size)
            }
            .onChange(of: isGoal) { oldValue, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        gradientOffset = 1.0
                    }
                } else {
                    gradientOffset = -1.0
                }
            }
            .onAppear {
                resetPositions(in: size)
            }
            .alert(isPresented: $gameOver) {
                Alert(
                    title: Text("Game Over"),
                    message: Text(winnerMessage),
                    dismissButton: .default(Text("Play Again")) {
                        player1Score = 0
                        player2Score = 0
                        isGoal = false
                        resetPositions(in: size)
                    }
                )
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    // MARK: - Game Logic Methods
    
    private func updatePuck(in size: CGSize) {
        // Apply velocity to position
        puckPosition.x += puckVelocity.dx
        puckPosition.y += puckVelocity.dy
        
        // Apply friction to slow the puck down naturally
        puckVelocity.dx *= friction
        puckVelocity.dy *= friction
        
        // Cap maximum speed
        let speed = sqrt(puckVelocity.dx * puckVelocity.dx + puckVelocity.dy * puckVelocity.dy)
        if speed > maxSpeed {
            puckVelocity.dx = (puckVelocity.dx / speed) * maxSpeed
            puckVelocity.dy = (puckVelocity.dy / speed) * maxSpeed
        }
    }
    
    private func moveAI(in size: CGSize) {
        let aiHomeY = size.height * 0.15
        var targetPosition = CGPoint(x: size.width / 2, y: aiHomeY)
        
        // Attack if puck is on AI's side, otherwise defend
        if puckPosition.y < size.height / 2 {
            targetPosition = puckPosition
            targetPosition.y = min(targetPosition.y, (size.height / 2) - malletRadius) // Don't cross center line
        } else {
            targetPosition.x = puckPosition.x
        }
        
        // Ensure AI stays within table bounds
        targetPosition.x = max(malletRadius, min(size.width - malletRadius, targetPosition.x))
        
        let dx = targetPosition.x - player2MalletPosition.x
        let dy = targetPosition.y - player2MalletPosition.y
        let distance = sqrt(dx * dx + dy * dy)
        
        if distance > aiSpeed {
            player2MalletPosition.x += (dx / distance) * aiSpeed
            player2MalletPosition.y += (dy / distance) * aiSpeed
        } else {
            player2MalletPosition = targetPosition
        }
    }
    
    private func detectCollisions(in size: CGSize) {
        // 1. Wall Collisions
        if puckPosition.x - puckRadius <= 0 {
            puckPosition.x = puckRadius
            puckVelocity.dx *= -1
        } else if puckPosition.x + puckRadius >= size.width {
            puckPosition.x = size.width - puckRadius
            puckVelocity.dx *= -1
        }
        
        // Check top/bottom walls (ignoring the goal area)
        let inGoalXRange = puckPosition.x > (size.width / 2 - goalWidth / 2) && puckPosition.x < (size.width / 2 + goalWidth / 2)
        
        if !inGoalXRange {
            if puckPosition.y - puckRadius <= 0 {
                puckPosition.y = puckRadius
                puckVelocity.dy *= -1
            } else if puckPosition.y + puckRadius >= size.height {
                puckPosition.y = size.height - puckRadius
                puckVelocity.dy *= -1
            }
        }
        
        // 2. Mallet Collisions
        handleMalletCollision(with: player1MalletPosition)
        handleMalletCollision(with: player2MalletPosition)
    }
    
    private func handleMalletCollision(with malletPos: CGPoint) {
        var dx = puckPosition.x - malletPos.x
        var dy = puckPosition.y - malletPos.y
        
        // Prevent NaN if coordinates are exactly identical
        if dx == 0 && dy == 0 {
            dx = 0.1
            dy = 0.1
        }
        
        let distance = sqrt(dx * dx + dy * dy)
        let minDistance = puckRadius + malletRadius
        
        if distance < minDistance {
            // Normalize the collision vector
            let nx = dx / distance
            let ny = dy / distance
            
            // Push puck outside the mallet to prevent it from getting stuck
            let overlap = minDistance - distance
            puckPosition.x += nx * overlap
            puckPosition.y += ny * overlap
            
            // Apply bounce velocity based on hit angle
            let hitPower: CGFloat = 15.0
            puckVelocity.dx = nx * hitPower
            puckVelocity.dy = ny * hitPower
        }
    }
    
    private func checkGoals(in size: CGSize) {
        if puckPosition.y + puckRadius < 0 {
            // Player 1 scored!
            player1Score += 1
            if player1Score >= 5 {
                triggerGameOver(winner: "Player (Blue)")
            } else {
                triggerGoalSequence(in: size)
            }
        } else if puckPosition.y - puckRadius > size.height {
            // Player 2 scored!
            player2Score += 1
            if player2Score >= 5 {
                triggerGameOver(winner: "AI (Red)")
            } else {
                triggerGoalSequence(in: size)
            }
        }
    }
    
    private func triggerGameOver(winner: String) {
        winnerMessage = "\(winner) Wins!"
        gameOver = true
    }
    
    private func triggerGoalSequence(in size: CGSize) {
        isGoal = true
        
        // Pause briefly, then reset for the next round
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isGoal = false
            resetPositions(in: size)
        }
    }
    
    private func resetPositions(in size: CGSize) {
        puckPosition = CGPoint(x: size.width / 2, y: size.height / 2)
        puckVelocity = CGVector(dx: 0, dy: 0)
        
        player1MalletPosition = CGPoint(x: size.width / 2, y: size.height * 0.8)
        player2MalletPosition = CGPoint(x: size.width / 2, y: size.height * 0.2)
    }
}

#Preview {
    AirHockey()
}
