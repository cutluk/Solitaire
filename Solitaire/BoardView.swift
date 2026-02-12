//
//  BoardView.swift
//  Solitaire
//
//  Created by Luke Cutting on 7/1/22.
//

import SwiftUI

// MARK: - Card View with Flip Animation

struct CardView: View {
    let card: Card

    @State private var isFlipping = false
    @State private var displayFront = false

    var body: some View {
        Image(displayFront ? card.id : "card0")
            .resizable()
            .scaledToFit()
            .rotation3DEffect(
                .degrees(isFlipping ? 90 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0.5
            )
            .onAppear {
                displayFront = card.isFlipped
            }
            .onChange(of: card.isFlipped) { newValue in
                // First half: rotate to edge-on (90 degrees)
                withAnimation(.easeIn(duration: 0.2)) {
                    isFlipping = true
                }
                // Midpoint: swap the image, then rotate back to flat
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    displayFront = newValue
                    withAnimation(.easeOut(duration: 0.2)) {
                        isFlipping = false
                    }
                }
            }
    }
}

// MARK: - Board View

struct BoardView: View {
    @ObservedObject var board: Board
    @Namespace private var cardAnimation

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
                withAnimation(.easeInOut(duration: 0.3)) {
                    board.newGame()
                }
            }
        }
    }

    // MARK: - Top Row

    var topRow: some View {
        HStack {
            // 4 foundation piles
            ForEach(0..<4, id: \.self) { i in
                ZStack {
                    // Empty slot background
                    Image("card69")
                        .resizable()
                        .frame(width: cardWidth, height: cardHeight)

                    // Top card on this foundation
                    if let topCard = board.foundations[i].last {
                        CardView(card: topCard)
                            .frame(width: cardWidth, height: cardHeight)
                            .matchedGeometryEffect(id: topCard.id, in: cardAnimation)
                    }
                }
                .padding(-14)
                .padding(.trailing, 23)
                .padding(.leading, -1)
            }

            Spacer()

            // Revealed (waste) pile
            ZStack {
                Image("card69")
                    .resizable()
                    .frame(width: cardWidth, height: cardHeight)

                if let topCard = board.revealed.last {
                    CardView(card: topCard)
                        .frame(width: cardWidth, height: cardHeight)
                        .matchedGeometryEffect(id: topCard.id, in: cardAnimation)
                }
            }
            .padding(-14)
            .padding(.trailing, 23)
            .padding(.leading, -1)
            .onTapGesture {
                withAnimation(.easeInOut(duration: 0.3)) {
                    board.tapRevealed()
                }
            }

            // Stock (deck)
            Image(board.deck.cards.isEmpty ? "card69" : "card0")
                .resizable()
                .frame(width: cardWidth, height: cardHeight)
                .padding(-14)
                .onTapGesture {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        board.tapDeck()
                    }
                }
        }
    }

    // MARK: - Tableau

    var tableau: some View {
        HStack(alignment: .top) {
            ForEach(0..<7, id: \.self) { colIndex in
                VStack(spacing: 0) {
                    if board.columns[colIndex].isEmpty {
                        // Empty column placeholder — keeps spacing and accepts king taps
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: 47, height: 75)
                            .padding([.leading, .trailing], -14)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    board.tapEmptyColumn(columnIndex: colIndex)
                                }
                            }
                    } else {
                        ForEach(
                            Array(board.columns[colIndex].enumerated()),
                            id: \.element.id
                        ) { cardIndex, card in
                            CardView(card: card)
                                .frame(width: 75, height: 75)
                                .matchedGeometryEffect(id: card.id, in: cardAnimation)
                                .padding(.bottom, -50)
                                .padding([.leading, .trailing], -14)
                                .onTapGesture {
                                    withAnimation(.easeInOut(duration: 0.3)) {
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
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        BoardView(board: .initial())
            .previewInterfaceOrientation(.portrait)
    }
}
