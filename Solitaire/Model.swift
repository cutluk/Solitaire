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
        //MAP: func map<A>(_ tranform: (A) -> B) -> B {}
        //FLATMAP: flatMap<A>(transform (A) -> [B]) -> B
        //[[Card]] -> [Card]
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
// Slower implementation
//extension Array where Element == Card {
//    mutating func flipBottomCard() {
//        if var last = self.popLast() {
//            self.append(last.flip())
//        }
//    }
//}
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
    //    board.revealed.append(board.deck.drawAndFlip()!)
        
        
        //dump(board)
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



//Board.initial
//
//dump(Board.initial)
//
//func eatCherries(bagOfCherries: [Cherry]) -> BowlOfPits {
//    bagOfCherries
//        .map{ cherry in
//        putCherryInMouth(cherry)
//        }
//        .map{ cherry in
//            SeperatePit(from: cherry)
//
//        }
//        .map{ goodStuff in
//            eatgoodStuff(goodStuff)
//        }
//        .map{ pit in
//            SpitItOut(pit)
//        }
//
//    bagOfCherries
//        .map{
//        putCherryInMouth($0)
//        }
//        .map{ cherry in
//            SeperatePit(from: $0)
//
//        }
//        .map{
//            eatgoodStuff($0)
//        }
//        .map{
//            SpitItOut($0)
//        }
//}
