//
//  Model.swift
//  Solitaire
//
//  Created by Luke Cutting on 7/1/22.
//

import Foundation
import SwiftUI

enum Suite: String, CaseIterable {
    case diamonds
    case spades
    case clubs
    case hearts
}


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

struct Card {
    let value: Value
    let suite: Suite
    var isFlipped: Bool = false
}
extension Card {
    var imageName: String {
        self.isFlipped
        ? "\(self.value) \(self.suite)"
        : "card0"
    }
}
extension Card: Identifiable {
    var id: String { "\(self.value) \(self.suite)" }
}
extension Card {
    mutating func flip() -> Card {
        self.isFlipped.toggle()
        return self 
    }
}

enum Color {
    case black
    case red
}

extension Card {
    var color: Color {
        switch self.suite {
            case .diamonds, .hearts:
                return .red
            case .spades, .clubs:
                return .black
        }
    }
}

final class Deck {
   
    var cards: [Card] = {

        return Suite.allCases.flatMap { suite in
            Value.allCases.map{ value in
                Card(value: value, suite: suite)
            }
        }
    }()
}
extension Deck {

    func draw() -> Card?{
        self.cards.popLast()
    }
    func draw(_ count: Int) -> [Card]{
        
        Array(repeating: 0, count: count).compactMap { _ in
            self.cards.popLast()
        }
    }
    func drawAndFlip() -> Card? {
        var card = self.draw()
        return card?.flip()
    }
    func shuffle() {
        self.cards.shuffle()
    }
}

extension Array where Element == Card {
    mutating func flipBottomCard() -> [Card] {
        self[self.count - 1].isFlipped.toggle()
        return self
    }
}

// value and reference semantics
final class Board: ObservableObject {
    @Published var deck = Deck()
    @Published var revealed: [Card] = []
    @Published var columns: [[Card]] = []
    @Published var slots: [[Card]] = []
}

extension Board{
    static func initial() -> Board {
        let board = Board()
        board.deck.shuffle()
        board.columns = [
            board.deck.draw(1),
            board.deck.draw(2),
            board.deck.draw(3),
            board.deck.draw(4),
            board.deck.draw(5),
            board.deck.draw(6),
            board.deck.draw(7)
        ]
            .map {
                var col = $0
                return col.flipBottomCard()
            }

       return board
    }
}

extension Board {
    func reveal() {
        if let drawn = deck.drawAndFlip() {
            revealed.append(drawn)
        }
    }
}

extension Board {
    func moveAvailable(columnindex: Int){
        // scan board for matching card
        self.columns.map{
            $0.last
        }
        // allows you to grab column value and index
            .enumerated()
        // for loop checking if card types will match
            .map{
                // creating new card using the bottom of the selected column
                guard let card = self.columns[columnindex].last else{return}
                // if (== ++ && != color)
                if ($0.element?.value.rawValue == card.value.rawValue + 1) && ($0.element?.color != card.color) {
                    // move card to bottom of selected column and delete its previous position
                    
                    self.columns[$0.offset].append(self.columns[columnindex].removeLast())
                    // flip over bottom card in column
                    
//                    /* Make sure that card doesn't get re-flipped when moving between two potential values*/
    
                    guard (!self.columns[columnindex].isEmpty) && (!self.columns[columnindex].last!.isFlipped) else{return}
                    self.columns[columnindex] = self.columns[columnindex].flipBottomCard()
                }
            }
    }
    
    func moveFromDeck(){
        self.columns.map{
            $0.last
        }
            .enumerated()
            .map{
                // NOT SURE IF REVEALED IS THE CORRECT WAY TO GRAB THE DECK VALUE
                guard let card = revealed.last else{return}
                // if (== ++ && != color)
                if ($0.element?.value.rawValue == card.value.rawValue + 1) && ($0.element?.color != card.color) {
                    // move card from top right deck and delete it from the top right deck position
                    self.columns[$0.offset].append(card)
                    print(self.revealed[$0.offset])
                    
            }
    }
}

}
