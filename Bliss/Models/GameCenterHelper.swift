//
//  GameCenterHelper.swift
//  Bliss
//
//  Created by Bu on 27/3/26.
//

import Foundation
import SwiftUI
import GameKit
import Combine

// MARK: - Game Center Helper
class GameCenterHelper: NSObject, ObservableObject, GKGameCenterControllerDelegate {
    @Published var isAuthenticated = false
    @Published var showLeaderboard = false
    
    static let shared = GameCenterHelper()
    
    override init() {
        super.init()
        authenticateUser()
    }
    
    func authenticateUser() {
        GKLocalPlayer.local.authenticateHandler = { vc, error in
            if let _ = vc {
                // Cannot present VC easily from here without a window,
                // but we handle basic auth state
            } else if GKLocalPlayer.local.isAuthenticated {
                DispatchQueue.main.async {
                    self.isAuthenticated = true
                }
            } else {
                print("Game Center Auth Failed: \(error?.localizedDescription ?? "Unknown")")
            }
        }
    }
    
    func reportScore(_ score: Int) {
        if isAuthenticated {
            let scoreReporter = GKScore(leaderboardIdentifier: "com.bliss.spaceinvaders.highscore")
            scoreReporter.value = Int64(score)
            GKScore.report([scoreReporter]) { error in
                if let error = error {
                    print("Error reporting score: \(error.localizedDescription)")
                }
            }
        }
    }
    
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
        DispatchQueue.main.async {
            self.showLeaderboard = false
        }
    }
}

// MARK: - SwiftUI Game Center View
struct GameCenterView: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> UIViewController {
        let vc = GKGameCenterViewController(state: .leaderboards)
        vc.gameCenterDelegate = GameCenterHelper.shared
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
}
