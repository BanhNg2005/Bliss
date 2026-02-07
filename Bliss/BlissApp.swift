//
//  BlissApp.swift
//  Bliss
//
//  Created by Bu on 6/2/26.
//

import SwiftUI
import CoreData
import FirebaseCore

@main
struct BlissApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView(sessionStore: SessionStore())
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
