//
//  SolitaireApp.swift
//  Solitaire
//
//  Created by Luke Cutting on 5/15/22.
//

import RevenueCat
import SwiftUI

@main
struct SolitaireApp: App {
    @StateObject private var board = Board.initial()
    @StateObject private var store = StoreManager()

    init() {
        // Configure RevenueCat in observer mode.
        // Your app keeps handling purchases via StoreKit 2;
        // RevenueCat simply tracks them for analytics/dashboard.
        Purchases.logLevel = .debug  // Remove or set to .warn for production
        Purchases.configure(
            with: .init(withAPIKey: "appl_kTwtyRzYoMrbqFJwzgQJKWDCoXU")
                .with(purchasesAreCompletedBy: .myApp, storeKitVersion: .storeKit2)
        )
    }

    var body: some Scene {
        WindowGroup {
            BoardView(board: board, store: store)
        }
    }
}
