//
//  ContentView.swift
//  Bliss
//
//  Created by Bu on 6/2/26.
//

import SwiftUI
import CoreData

struct ContentView: View {
    @ObservedObject var sessionStore: SessionStore
    @StateObject private var authViewModel: AuthViewModel
    @State private var pendingDeepLink: URL?

    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
        _authViewModel = StateObject(wrappedValue: AuthViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        if sessionStore.isLoggedIn {
            RootTabView(sessionStore: sessionStore)
                .onOpenURL { url in
                    NotificationCenter.default.post(name: .init("bliss.openURL"), object: url)
                }
        } else {
            AuthView(viewModel: authViewModel)
        }
    }
}

#Preview {
    ContentView(sessionStore: SessionStore())
        .environment(\.managedObjectContext, PersistenceController.preview.container.viewContext)
}
