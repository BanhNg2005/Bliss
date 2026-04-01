//
//  Config.swift
//  Bliss
//
//  Created by Bu on 30/3/26.
//

import Foundation
import SwiftUI

let config = GameConfig(playerOneConfig: PlayerConfig(color: .orange, image: Image(systemName: "tortoise")),
                        playerTwoConfig: PlayerConfig(color: .blue, image: Image(systemName: "hare")),
                        columns: 7,
                        rows: 6,
                        tilesToWin: 4,
                        primaryColor: .purple,
                        secondaryColor: .white,
                        backgroundImage: Image("wallpaper"))
