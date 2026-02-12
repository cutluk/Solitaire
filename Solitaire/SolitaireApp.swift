//
//  SolitaireApp.swift
//  Solitaire
//
//  Created by Luke Cutting on 5/15/22.
//

import SwiftUI

@main
struct SolitaireApp: App {
    @StateObject private var board = Board.initial()
    @StateObject private var store = StoreManager()

    var body: some Scene {
        WindowGroup {
            BoardView(board: board, store: store)
        }
    }
}
