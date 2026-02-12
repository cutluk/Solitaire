//
//  Model.swift
//  Solitaire
//
//  Created by Luke Cutting on 7/1/22.
//

import Foundation
import SwiftUI

// MARK: - Suit

enum Suit: String, CaseIterable {
    case diamonds
    case spades
    case clubs
    case hearts
}

// MARK: - Value

enum Value: Int, CaseIterable {
    case ace = 1
    case two = 2
    case three = 3
    case four = 4
    case five = 5
    case six = 6
    case seven = 7
    case eight = 8
    case nine = 9
    case ten = 10
    case jack = 11
    case queen = 12
    case king = 13
}

// MARK: - CardColor

enum CardColor {
    case black
    case red
}

// MARK: - Card

struct Card: Identifiable, Equatable {
    let value: Value
    let suit: Suit
    var isFlipped: Bool = false

    var id: String { "\(value) \(suit)" }

    var imageName: String {
        isFlipped ? "\(value) \(suit)" : "card0"
    }

    var color: CardColor {
        switch suit {
        case .diamonds, .hearts: return .red
        case .spades, .clubs: return .black
        }
    }

    mutating func flip() {
        isFlipped.toggle()
    }
}

// MARK: - Deck

struct Deck: Equatable {
    var cards: [Card] = Suit.allCases.flatMap { suit in
        Value.allCases.map { value in
            Card(value: value, suit: suit)
        }
    }

    mutating func draw() -> Card? {
        cards.popLast()
    }

    mutating func draw(_ count: Int) -> [Card] {
        (0..<count).compactMap { _ in cards.popLast() }
    }

    mutating func drawAndFlip() -> Card? {
        guard var card = draw() else { return nil }
        card.flip()
        return card
    }

    mutating func shuffle() {
        cards.shuffle()
    }
}

// MARK: - Board Snapshot (for undo)

struct BoardSnapshot {
    let deckCards: [Card]
    let revealed: [Card]
    let columns: [[Card]]
    let foundations: [[Card]]
}

// MARK: - Board

final class Board: ObservableObject {
    @Published var deck = Deck()
    @Published var revealed: [Card] = []
    @Published var columns: [[Card]] = []
    @Published var foundations: [[Card]] = [[], [], [], []]
    @Published var hasWon: Bool = false
    @Published var canUndo: Bool = false

    private var history: [BoardSnapshot] = []
    private static let maxHistoryCount = 30

    /// Save the current state before making a move
    func saveSnapshot() {
        if history.count >= Self.maxHistoryCount {
            history.removeFirst()
        }
        history.append(BoardSnapshot(
            deckCards: deck.cards,
            revealed: revealed,
            columns: columns,
            foundations: foundations
        ))
        canUndo = true
    }

    /// Restore the previous state
    func undo() {
        guard let snapshot = history.popLast() else { return }
        deck.cards = snapshot.deckCards
        revealed = snapshot.revealed
        columns = snapshot.columns
        foundations = snapshot.foundations
        hasWon = false
        canUndo = !history.isEmpty
    }
}

// MARK: - Setup

extension Board {
    static func initial() -> Board {
        let board = Board()
        board.deck.shuffle()
        board.columns = (1...7).map { count in
            var cards = board.deck.draw(count)
            if !cards.isEmpty {
                cards[cards.count - 1].isFlipped = true
            }
            return cards
        }
        return board
    }

    func newGame() {
        var freshDeck = Deck()
        freshDeck.shuffle()
        columns = (1...7).map { count in
            var cards = freshDeck.draw(count)
            if !cards.isEmpty {
                cards[cards.count - 1].isFlipped = true
            }
            return cards
        }
        deck = freshDeck
        revealed = []
        foundations = [[], [], [], []]
        hasWon = false
        history.removeAll()
        canUndo = false
    }
}

// MARK: - Validation

extension Board {
    /// Can this card be placed on the given foundation pile?
    func canPlaceOnFoundation(card: Card, foundationIndex: Int) -> Bool {
        if let top = foundations[foundationIndex].last {
            return card.suit == top.suit && card.value.rawValue == top.value.rawValue + 1
        } else {
            return card.value == .ace
        }
    }

    /// Can this card be placed on top of the given tableau column?
    func canPlaceOnColumn(card: Card, columnIndex: Int) -> Bool {
        if let top = columns[columnIndex].last {
            return card.color != top.color && card.value.rawValue == top.value.rawValue - 1
        } else {
            return card.value == .king
        }
    }

    /// Find a foundation pile where this card can be placed
    func findFoundation(for card: Card) -> Int? {
        for i in 0..<4 where canPlaceOnFoundation(card: card, foundationIndex: i) {
            return i
        }
        return nil
    }

    /// Find a tableau column where this card can be placed (prefers non-empty columns)
    func findColumn(for card: Card, excluding: Int = -1) -> Int? {
        // Prefer non-empty columns over empty ones
        for i in 0..<7 where i != excluding && !columns[i].isEmpty
            && canPlaceOnColumn(card: card, columnIndex: i) {
            return i
        }
        for i in 0..<7 where i != excluding && columns[i].isEmpty
            && canPlaceOnColumn(card: card, columnIndex: i) {
            return i
        }
        return nil
    }
}

// MARK: - Move Availability

extension Board {
    /// Can the top revealed card be moved anywhere?
    func canMoveRevealed() -> Bool {
        guard let card = revealed.last else { return false }
        return findFoundation(for: card) != nil || findColumn(for: card) != nil
    }

    /// Can the card at this position in the column be moved anywhere?
    func canMoveColumn(columnIndex: Int, cardIndex: Int) -> Bool {
        guard cardIndex < columns[columnIndex].count else { return false }
        let card = columns[columnIndex][cardIndex]
        guard card.isFlipped else { return false }
        let isTopCard = cardIndex == columns[columnIndex].count - 1
        if isTopCard, findFoundation(for: card) != nil { return true }
        if findColumn(for: card, excluding: columnIndex) != nil { return true }
        return false
    }
}

// MARK: - Helpers

extension Board {
    /// Flip the new top card of a column face-up if it's currently face-down
    func exposeTopCard(in columnIndex: Int) {
        guard !columns[columnIndex].isEmpty else { return }
        let last = columns[columnIndex].count - 1
        if !columns[columnIndex][last].isFlipped {
            columns[columnIndex][last].isFlipped = true
        }
    }

    /// Check if all four foundations are complete (Ace through King)
    func checkWin() {
        hasWon = foundations.allSatisfy { $0.count == 13 }
    }

    /// Whether all remaining cards can be auto-completed to foundations
    var canAutoComplete: Bool {
        // Deck must be empty
        guard deck.cards.isEmpty else { return false }
        // All tableau cards must be face-up
        let allFaceUp = columns.allSatisfy { column in
            column.allSatisfy { $0.isFlipped }
        }
        guard allFaceUp else { return false }
        // Must still have cards to move
        return !hasWon
    }

    /// The next card that can be moved to a foundation during auto-complete
    func nextAutoCompleteCard() -> Card? {
        for column in columns {
            if let card = column.last, findFoundation(for: card) != nil {
                return card
            }
        }
        if let card = revealed.last, findFoundation(for: card) != nil {
            return card
        }
        return nil
    }

    /// Move one card to its foundation during auto-complete. Returns true if a card was moved.
    func autoCompleteOneCard() -> Bool {
        for colIndex in 0..<columns.count {
            if let card = columns[colIndex].last,
               let fi = findFoundation(for: card) {
                foundations[fi].append(columns[colIndex].removeLast())
                checkWin()
                return true
            }
        }
        if let card = revealed.last,
           let fi = findFoundation(for: card) {
            foundations[fi].append(revealed.removeLast())
            checkWin()
            return true
        }
        return false
    }
}

// MARK: - Actions

extension Board {
    /// Tap the stock pile (deck) to reveal a card, or recycle if empty
    func tapDeck() {
        saveSnapshot()
        if deck.cards.isEmpty {
            // Recycle: flip revealed cards back into stock
            deck.cards = revealed.reversed().map { card in
                var c = card
                c.isFlipped = false
                return c
            }
            revealed.removeAll()
        } else if let card = deck.drawAndFlip() {
            revealed.append(card)
        }
    }

    /// Tap the revealed (waste) pile to move the top card
    func tapRevealed() {
        guard let card = revealed.last else { return }

        // Try foundation first
        if let fi = findFoundation(for: card) {
            saveSnapshot()
            foundations[fi].append(revealed.removeLast())
            checkWin()
            return
        }

        // Try tableau column
        if let ci = findColumn(for: card) {
            saveSnapshot()
            columns[ci].append(revealed.removeLast())
            return
        }
    }

    /// Tap a card in a tableau column
    func tapColumn(columnIndex: Int, cardIndex: Int) {
        guard cardIndex < columns[columnIndex].count else { return }
        let card = columns[columnIndex][cardIndex]

        // Can't interact with face-down cards
        guard card.isFlipped else { return }

        let isTopCard = cardIndex == columns[columnIndex].count - 1

        // If it's the top card, try moving to a foundation pile first
        if isTopCard, let fi = findFoundation(for: card) {
            saveSnapshot()
            foundations[fi].append(columns[columnIndex].removeLast())
            exposeTopCard(in: columnIndex)
            checkWin()
            return
        }

        // Try moving this card (and all cards on top of it) to another column
        if let targetCol = findColumn(for: card, excluding: columnIndex) {
            saveSnapshot()
            let moving = Array(columns[columnIndex][cardIndex...])
            columns[targetCol].append(contentsOf: moving)
            columns[columnIndex].removeSubrange(cardIndex...)
            exposeTopCard(in: columnIndex)
            return
        }
    }

    /// Tap an empty column slot — move a king here from revealed or another column
    func tapEmptyColumn(columnIndex: Int) {
        guard columns[columnIndex].isEmpty else { return }

        // Check revealed pile for a king
        if let card = revealed.last, card.value == .king {
            saveSnapshot()
            columns[columnIndex].append(revealed.removeLast())
            return
        }

        // Check other columns for a king at the start of a face-up sequence
        for i in 0..<7 where i != columnIndex && !columns[i].isEmpty {
            // Find the first face-up card in this column
            if let firstFaceUp = columns[i].firstIndex(where: { $0.isFlipped }) {
                let card = columns[i][firstFaceUp]
                if card.value == .king && firstFaceUp > 0 {
                    // Only move if the king isn't already at the base (pointless move)
                    saveSnapshot()
                    let moving = Array(columns[i][firstFaceUp...])
                    columns[columnIndex].append(contentsOf: moving)
                    columns[i].removeSubrange(firstFaceUp...)
                    exposeTopCard(in: i)
                    return
                }
            }
        }
    }
}
