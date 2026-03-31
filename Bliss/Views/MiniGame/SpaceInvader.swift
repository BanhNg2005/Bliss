//
//  SpaceInvader.swift
//  Bliss
//
//  Created by Bu on 27/3/26.
//

import SwiftUI
import SpriteKit
import GameKit

// MARK: - Physics Categories
struct PhysicsCategory {
    static let none: UInt32 = 0
    static let player: UInt32 = 0b1
    static let playerLaser: UInt32 = 0b10
    static let enemy: UInt32 = 0b100
    static let enemyLaser: UInt32 = 0b1000
}

// MARK: - Space Invader Game Scene
class SpaceInvaderScene: SKScene, SKPhysicsContactDelegate {
    var player: SKSpriteNode!
    var scoreLabel: SKLabelNode!
    
    var score = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
            checkDifficulty()
        }
    }
    
    var isGameOver = false
    var gameOverCallback: ((Int) -> Void)?
    
    // Difficulty Modifiers
    var enemyMoveSpeed: TimeInterval = 1.0
    var enemyFireRate: TimeInterval = 2.0
    var nextDifficultyScore = 500
    
    var movingRight = true
    var enemyNodes: [SKSpriteNode] = []
    
    override func didMove(to view: SKView) {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
        backgroundColor = .black
        
        setupPlayer()
        setupScore()
        spawnEnemies()
        
        // Auto fire
        let shootAction = SKAction.sequence([
            SKAction.run { [weak self] in self?.shoot() },
            SKAction.wait(forDuration: 0.5)
        ])
        run(SKAction.repeatForever(shootAction), withKey: "playerShooting")
        
        // Enemy logic loops
        startEnemyMovement()
        startEnemyShooting()
    }
    
    func setupPlayer() {
        player = SKSpriteNode(color: .cyan, size: CGSize(width: 40, height: 40))
        player.position = CGPoint(x: size.width / 2, y: 100)
        player.physicsBody = SKPhysicsBody(rectangleOf: player.size)
        player.physicsBody?.isDynamic = true
        player.physicsBody?.categoryBitMask = PhysicsCategory.player
        player.physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.enemyLaser
        player.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(player)
    }
    
    func setupScore() {
        scoreLabel = SKLabelNode(fontNamed: "Courier-Bold")
        scoreLabel.text = "Score: 0"
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .white
        scoreLabel.position = CGPoint(x: 20, y: size.height - 50)
        scoreLabel.horizontalAlignmentMode = .left
        addChild(scoreLabel)
    }
    
    func spawnEnemies() {
        let rows = 4
        let cols = 6
        let xOffset: CGFloat = size.width / CGFloat(cols + 2)
        let yOffset: CGFloat = 50
        
        for row in 0..<rows {
            for col in 0..<cols {
                let enemy = SKSpriteNode(color: .red, size: CGSize(width: 30, height: 30))
                let x = xOffset * CGFloat(col + 1)
                let y = size.height - 100 - (yOffset * CGFloat(row))
                enemy.position = CGPoint(x: x, y: y)
                
                enemy.physicsBody = SKPhysicsBody(rectangleOf: enemy.size)
                enemy.physicsBody?.isDynamic = true
                enemy.physicsBody?.categoryBitMask = PhysicsCategory.enemy
                enemy.physicsBody?.contactTestBitMask = PhysicsCategory.playerLaser
                enemy.physicsBody?.collisionBitMask = PhysicsCategory.none
                
                addChild(enemy)
                enemyNodes.append(enemy)
            }
        }
    }
    
    func startEnemyMovement() {
        removeAction(forKey: "enemyMovement")
        let moveAction = SKAction.sequence([
            SKAction.run { [weak self] in self?.updateEnemyPositions() },
            SKAction.wait(forDuration: enemyMoveSpeed)
        ])
        run(SKAction.repeatForever(moveAction), withKey: "enemyMovement")
    }
    
    func updateEnemyPositions() {
        var hitEdge = false
        enemyNodes = enemyNodes.filter { $0.parent != nil }
        
        if enemyNodes.isEmpty {
            // Next wave
            spawnEnemies()
            return
        }
        
        for enemy in enemyNodes {
            if movingRight && enemy.position.x + 20 > size.width {
                hitEdge = true
            } else if !movingRight && enemy.position.x - 20 < 0 {
                hitEdge = true
            }
        }
        
        if hitEdge {
            movingRight.toggle()
            for enemy in enemyNodes {
                enemy.position.y -= 20
                if enemy.position.y < player.position.y {
                    triggerGameOver()
                }
            }
        } else {
            let dx: CGFloat = movingRight ? 20 : -20
            for enemy in enemyNodes {
                enemy.position.x += dx
            }
        }
    }
    
    func startEnemyShooting() {
        removeAction(forKey: "enemyShooting")
        let shootAction = SKAction.sequence([
            SKAction.wait(forDuration: enemyFireRate),
            SKAction.run { [weak self] in self?.enemyShoot() }
        ])
        run(SKAction.repeatForever(shootAction), withKey: "enemyShooting")
    }
    
    func enemyShoot() {
        let validEnemies = enemyNodes.filter { $0.parent != nil }
        guard !validEnemies.isEmpty, !isGameOver else { return }
        
        if let shooter = validEnemies.randomElement() {
            let laser = SKSpriteNode(color: .yellow, size: CGSize(width: 4, height: 15))
            laser.position = shooter.position
            laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
            laser.physicsBody?.isDynamic = true
            laser.physicsBody?.categoryBitMask = PhysicsCategory.enemyLaser
            laser.physicsBody?.contactTestBitMask = PhysicsCategory.player
            laser.physicsBody?.collisionBitMask = PhysicsCategory.none
            addChild(laser)
            
            let move = SKAction.moveTo(y: -50, duration: 2.0)
            let remove = SKAction.removeFromParent()
            laser.run(SKAction.sequence([move, remove]))
        }
    }
    
    func shoot() {
        guard !isGameOver else { return }
        let laser = SKSpriteNode(color: .green, size: CGSize(width: 4, height: 15))
        laser.position = CGPoint(x: player.position.x, y: player.position.y + 20)
        laser.physicsBody = SKPhysicsBody(rectangleOf: laser.size)
        laser.physicsBody?.isDynamic = true
        laser.physicsBody?.categoryBitMask = PhysicsCategory.playerLaser
        laser.physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        laser.physicsBody?.collisionBitMask = PhysicsCategory.none
        addChild(laser)
        
        let move = SKAction.moveTo(y: size.height + 50, duration: 1.0)
        let remove = SKAction.removeFromParent()
        laser.run(SKAction.sequence([move, remove]))
    }
    
    func checkDifficulty() {
        if score >= nextDifficultyScore {
            nextDifficultyScore += 500
            enemyMoveSpeed = max(0.2, enemyMoveSpeed * 0.8)
            enemyFireRate = max(0.5, enemyFireRate * 0.8)
            startEnemyMovement()
            startEnemyShooting()
        }
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        let mask = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        
        if mask == (PhysicsCategory.playerLaser | PhysicsCategory.enemy) {
            let enemy = contact.bodyA.categoryBitMask == PhysicsCategory.enemy ? contact.bodyA.node : contact.bodyB.node
            let laser = contact.bodyA.categoryBitMask == PhysicsCategory.playerLaser ? contact.bodyA.node : contact.bodyB.node
            
            enemy?.removeFromParent()
            laser?.removeFromParent()
            score += 100
            
        } else if mask == (PhysicsCategory.enemyLaser | PhysicsCategory.player) || mask == (PhysicsCategory.enemy | PhysicsCategory.player) {
            triggerGameOver()
        }
    }
    
    func triggerGameOver() {
        guard !isGameOver else { return }
        isGameOver = true
        removeAllActions()
        player.removeFromParent()
        gameOverCallback?(score)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isGameOver else { return }
        let location = touch.location(in: self)
        player.position.x = max(20, min(size.width - 20, location.x))
    }
}

// MARK: - SwiftUI View
struct SpaceInvader: View {
    @State private var isGameOver = false
    @State private var finalScore = 0
    @StateObject private var gcHelper = GameCenterHelper.shared
    
    var scene: SKScene {
        let scene = SpaceInvaderScene(size: UIScreen.main.bounds.size)
        scene.scaleMode = .resizeFill
        scene.gameOverCallback = { score in
            self.finalScore = score
            self.isGameOver = true
            GameCenterHelper.shared.reportScore(score)
        }
        return scene
    }
    
    var body: some View {
        ZStack {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            
            if isGameOver {
                VStack(spacing: 20) {
                    Text("GAME OVER")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    
                    Text("Score: \(finalScore)")
                        .font(.title2)
                        .foregroundColor(.white)
                    
                    Button("Play Again") {
                        isGameOver = false
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    
                    Button("Leaderboards") {
                        gcHelper.showLeaderboard = true
                    }
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                .padding(40)
                .background(Color.black.opacity(0.8))
                .cornerRadius(20)
            }
        }
        .sheet(isPresented: $gcHelper.showLeaderboard) {
            GameCenterView()
        }
    }
}

#Preview {
    SpaceInvader()
}
