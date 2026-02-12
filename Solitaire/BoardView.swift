//
//  BoardView.swift
//  Solitaire
//
//  Created by Luke Cutting on 7/1/22.
//

import SwiftUI

struct BoardView: View {
    @ObservedObject var board: Board

    let cardWidth: CGFloat = 51
    let cardHeight: CGFloat = 75

    var body: some View {
        ZStack {
            Image("background")
                .resizable()
                .edgesIgnoringSafeArea(.all)

            VStack {
                topRow
                    .padding([.leading, .trailing], 20)
                    .padding(.bottom, 50)
                    .padding(.top, 30)

                tableau

                Spacer()
            }
        }
        .alert("You Win!", isPresented: $board.hasWon) {
            Button("New Game") {
                board.newGame()
            }
        }
    }

    // MARK: - Top Row

    var topRow: some View {
        HStack {
            // 4 foundation piles
            ForEach(0..<4, id: \.self) { i in
                Image(board.foundations[i].last?.imageName ?? "card69")
                    .resizable()
                    .frame(width: cardWidth, height: cardHeight)
                    .padding(-14)
                    .padding(.trailing, 23)
                    .padding(.leading, -1)
            }

            Spacer()

            // Revealed (waste) pile
            Image(board.revealed.last?.imageName ?? "card69")
                .resizable()
                .frame(width: cardWidth, height: cardHeight)
                .padding(-14)
                .padding(.trailing, 23)
                .padding(.leading, -1)
                .onTapGesture {
                    board.tapRevealed()
                }

            // Stock (deck)
            Image(board.deck.cards.isEmpty ? "card69" : "card0")
                .resizable()
                .frame(width: cardWidth, height: cardHeight)
                .padding(-14)
                .onTapGesture {
                    board.tapDeck()
                }
        }
    }

    // MARK: - Tableau

    var tableau: some View {
        HStack(alignment: .top) {
            ForEach(0..<7, id: \.self) { colIndex in
                VStack(spacing: 0) {
                    ForEach(
                        Array(board.columns[colIndex].enumerated()),
                        id: \.element.id
                    ) { cardIndex, card in
                        Image(card.imageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 75, height: 75)
                            .padding(.bottom, -50)
                            .padding([.leading, .trailing], -14)
                            .onTapGesture {
                                board.tapColumn(
                                    columnIndex: colIndex,
                                    cardIndex: cardIndex
                                )
                            }
                    }
                }
            }
        }
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        BoardView(board: .initial())
            .previewInterfaceOrientation(.portrait)
    }
}
