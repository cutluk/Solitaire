//
//  SolitaireApp.swift
//  Solitaire
//
//  Created by Luke Cutting on 5/15/22.
//

import SwiftUI

@main
struct SolitaireApp: App {
    var body: some Scene {
        WindowGroup {
            BoardView(board: .initial())
        }
    }
}
