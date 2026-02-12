//
//  BoardView.swift
//  Solitaire
//
//  Created by Luke Cutting on 7/1/22.
//

import SwiftUI

// MARK: - Card Image Cache
//
// Card images are 500×726 pixels but displayed at 51×75 points.
// Without downsampling, 52 cards consume ~75 MB of texture memory.
// By rendering thumbnails at the actual display resolution we drop to ~7 MB.

final class CardImageCache {
    static let shared = CardImageCache()
    private var cache: [String: UIImage] = [:]

    /// Point size at which every card is drawn on screen.
    private let displaySize = CGSize(width: 51, height: 75)

    private init() {}

    func image(named name: String) -> UIImage {
        if let cached = cache[name] { return cached }

        guard let original = UIImage(named: name) else { return UIImage() }

        let scale = UIScreen.main.scale
        let pixelSize = CGSize(
            width: displaySize.width * scale,
            height: displaySize.height * scale
        )

        // Use Apple's efficient thumbnail API (iOS 15+)
        guard let thumbnail = original.preparingThumbnail(of: pixelSize) else {
            return original
        }

        cache[name] = thumbnail
        return thumbnail
    }

    func clear() {
        cache.removeAll()
    }
}

// MARK: - Card View with Flip Animation

struct CardView: View, Equatable {
    let card: Card

    @State private var isFlipping = false
    @State private var displayFront = false

    static func == (lhs: CardView, rhs: CardView) -> Bool {
        lhs.card == rhs.card
    }

    var body: some View {
        Image(uiImage: CardImageCache.shared.image(named: displayFront ? card.id : "card0"))
            .resizable()
            .interpolation(.medium)
            .scaledToFit()
            .rotation3DEffect(
                .degrees(isFlipping ? 90 : 0),
                axis: (x: 0, y: 1, z: 0),
                perspective: 0
            )
            .onAppear {
                displayFront = card.isFlipped
            }
            .onChange(of: card.isFlipped) { newValue in
                withAnimation(.easeIn(duration: 0.2)) {
                    isFlipping = true
                }
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
    @AppStorage("winCount") private var winCount: Int = 0
    @State private var flyingCardID: String? = nil

    // Deck-draw flip animation state
    @State private var deckDrawAngle: Double = 0
    @State private var deckDrawOffset: CGFloat = 0
    @State private var showDrawnCardFace: Bool = true

    // Jiggle animation state
    @State private var jiggleCardID: String? = nil
    @State private var jiggleOffset: CGFloat = 0

    // Auto-complete state
    @State private var isAutoCompleting = false
    @State private var showAutoCompletePrompt = false

    // Win celebration state
    @State private var showWinCelebration = false
    @State private var celebrationScale: CGFloat = 0

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

                bottomBar
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            // Card overlay — all cards render here, above the entire layout
            cardOverlay
                .allowsHitTesting(false)

            // Win celebration overlay
            if showWinCelebration {
                celebrationOverlay
                    .zIndex(10000)
            }
        }
        .allowsHitTesting(!isAutoCompleting || showWinCelebration)
        .alert("All cards are face up!", isPresented: $showAutoCompletePrompt) {
            Button("Auto Complete") {
                startAutoComplete()
            }
            Button("I'll Finish Manually", role: .cancel) {
                showAutoCompletePrompt = false
            }
        } message: {
            Text("Would you like to auto complete the game or finish manually?")
        }
        .onChange(of: board.hasWon) { won in
            if won {
                winCount += 1
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    celebrationScale = 0
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showWinCelebration = true
                    }
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                        celebrationScale = 1.0
                    }
                }
            }
        }
    }

    // MARK: - Animated action helpers

    /// Reset deck-draw flip state to defaults
    private func resetDeckDraw() {
        deckDrawAngle = 0
        deckDrawOffset = 0
        showDrawnCardFace = true
    }

    /// Shake a card that has nowhere to go
    private func triggerJiggle(cardID: String) {
        jiggleCardID = cardID
        jiggleOffset = 5
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            withAnimation(.interpolatingSpring(stiffness: 800, damping: 8)) {
                jiggleOffset = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            jiggleCardID = nil
        }
    }

    /// Perform a board action with animation and flying-card z-boost
    private func animatedAction(cardID: String?, action: () -> Void) {
        resetDeckDraw()
        flyingCardID = cardID
        withAnimation(.easeInOut(duration: 0.3)) {
            action()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            flyingCardID = nil
            checkAndStartAutoComplete()
        }
    }

    // MARK: - Top Row

    var topRow: some View {
        HStack {
            // 4 foundation piles
            ForEach(0..<4, id: \.self) { i in
                ZStack {
                    // Empty slot with "A" marker
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        .frame(width: cardWidth, height: cardHeight)
                        .overlay(
                            Text("A")
                                .font(.title2.weight(.bold))
                                .foregroundColor(.white.opacity(0.25))
                        )

                    // Anchors for the top two foundation cards.
                    // Keeping the previous top card anchored in the overlay
                    // prevents a visual glitch when the new card lands.
                    ForEach(Array(board.foundations[i].suffix(2)), id: \.id) { card in
                        Color.clear
                            .frame(width: cardWidth, height: cardHeight)
                            .matchedGeometryEffect(id: card.id, in: cardAnimation, isSource: true)
                    }
                }
                .padding(-14)
                .padding(.trailing, 23)
                .padding(.leading, -1)
            }

            Spacer()

            // Revealed (waste) pile — invisible anchors
            ZStack {
                Image(uiImage: CardImageCache.shared.image(named: "card69"))
                    .resizable()
                    .interpolation(.medium)
                    .frame(width: cardWidth, height: cardHeight)

                // Previous card anchor (stays visible during a new draw)
                if board.revealed.count >= 2 {
                    let prevCard = board.revealed[board.revealed.count - 2]
                    Color.clear
                        .frame(width: cardWidth, height: cardHeight)
                        .matchedGeometryEffect(id: prevCard.id, in: cardAnimation, isSource: true)
                }

                // Top card anchor
                if let topCard = board.revealed.last {
                    Color.clear
                        .frame(width: cardWidth, height: cardHeight)
                        .matchedGeometryEffect(id: topCard.id, in: cardAnimation, isSource: true)
                }
            }
            .padding(-14)
            .padding(.trailing, 23)
            .padding(.leading, -1)
            .contentShape(Rectangle())
            .onTapGesture {
                if board.canMoveRevealed() {
                    animatedAction(cardID: board.revealed.last?.id) {
                        board.tapRevealed()
                    }
                } else if let card = board.revealed.last {
                    triggerJiggle(cardID: card.id)
                }
            }

            // Stock (deck)
            Image(uiImage: CardImageCache.shared.image(named: board.deck.cards.isEmpty ? "card69" : "card0"))
                .resizable()
                .interpolation(.medium)
                .frame(width: cardWidth, height: cardHeight)
                .padding(-14)
                .onTapGesture {
                    if board.deck.cards.isEmpty {
                        // Recycling waste back to stock
                        withAnimation(.easeInOut(duration: 0.3)) {
                            board.tapDeck()
                        }
                    } else {
                        // Drawing a card — flip from deck position
                        // 1. Start at deck position showing card back
                        deckDrawAngle = 0
                        deckDrawOffset = 65
                        showDrawnCardFace = false

                        // 2. Add the card to revealed (no animation wrapper)
                        board.tapDeck()

                        // 3. First half: rotate to edge-on, move partway
                        withAnimation(.easeIn(duration: 0.15)) {
                            deckDrawAngle = 90
                            deckDrawOffset = 32
                        }

                        // 4. Midpoint: swap to face, animate flat at waste pile
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            showDrawnCardFace = true
                            withAnimation(.easeOut(duration: 0.15)) {
                                deckDrawAngle = 0
                                deckDrawOffset = 0
                            }
                        }

                        // 5. Check auto-complete after animation finishes
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            checkAndStartAutoComplete()
                        }
                    }
                }
        }
    }

    // MARK: - Bottom Bar

    var bottomBar: some View {
        HStack {
            Button {
                withAnimation(.easeInOut(duration: 0.3)) {
                    board.undo()
                }
            } label: {
                Label("Undo", systemImage: "arrow.uturn.backward")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(board.canUndo ? .white : .white.opacity(0.4))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(board.canUndo ? 0.45 : 0.2))
                    )
            }
            .disabled(!board.canUndo)

            Spacer()

            HStack(spacing: 5) {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("\(winCount)")
                    .foregroundColor(.white)
            }
            .font(.subheadline.weight(.semibold))
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.45))
            )

            Spacer()

            Button {
                isAutoCompleting = false
                showAutoCompletePrompt = false
                showWinCelebration = false
                withAnimation(.easeInOut(duration: 0.3)) {
                    board.newGame()
                }
            } label: {
                Label("New Deal", systemImage: "shuffle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.black.opacity(0.45))
                    )
            }
        }
    }

    // MARK: - Tableau

    var tableau: some View {
        HStack(alignment: .top) {
            ForEach(0..<7, id: \.self) { colIndex in
                VStack(spacing: 0) {
                    if board.columns[colIndex].isEmpty {
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            .frame(width: cardWidth, height: cardHeight)
                            .frame(width: 75, height: 75)
                            .padding([.leading, .trailing], -14)
                            .onTapGesture {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    board.tapEmptyColumn(columnIndex: colIndex)
                                }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                                    checkAndStartAutoComplete()
                                }
                            }
                    } else {
                        ForEach(
                            Array(board.columns[colIndex].enumerated()),
                            id: \.element.id
                        ) { cardIndex, card in
                            let isLastCard = cardIndex == board.columns[colIndex].count - 1
                            Color.clear
                                .frame(width: 75, height: 75)
                                .matchedGeometryEffect(id: card.id, in: cardAnimation, isSource: true)
                                .padding(.bottom, isLastCard ? 0 : -50)
                                .padding([.leading, .trailing], -14)
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    if board.canMoveColumn(columnIndex: colIndex, cardIndex: cardIndex) {
                                        animatedAction(cardID: card.id) {
                                            board.tapColumn(
                                                columnIndex: colIndex,
                                                cardIndex: cardIndex
                                            )
                                        }
                                    } else if card.isFlipped {
                                        triggerJiggle(cardID: card.id)
                                    }
                                }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Card Overlay (renders all cards above everything)

    var cardOverlay: some View {
        ZStack {
            // Tableau cards
            ForEach(0..<7, id: \.self) { colIndex in
                ForEach(
                    Array(board.columns[colIndex].enumerated()),
                    id: \.element.id
                ) { cardIndex, card in
                    CardView(card: card)
                        .equatable()
                        .frame(width: 75, height: 75)
                        .offset(x: card.id == jiggleCardID ? jiggleOffset : 0)
                        .matchedGeometryEffect(id: card.id, in: cardAnimation, isSource: false)
                        .zIndex(zIndex(for: card.id, base: Double(colIndex * 20 + cardIndex)))
                }
            }

            // Foundation top two cards per pile.
            // Rendering the previous top card here (instead of as a static
            // layout image) keeps its view identity stable when a new card
            // lands, eliminating the end-of-animation glitch.
            ForEach(0..<4, id: \.self) { i in
                let topCards = Array(board.foundations[i].suffix(2))
                ForEach(topCards, id: \.id) { card in
                    let isTop = card.id == board.foundations[i].last?.id
                    Image(uiImage: CardImageCache.shared.image(named: card.id))
                        .resizable()
                        .interpolation(.medium)
                        .scaledToFit()
                        .frame(width: cardWidth, height: cardHeight)
                        .matchedGeometryEffect(id: card.id, in: cardAnimation, isSource: false)
                        .zIndex(isTop ? zIndex(for: card.id, base: 200 + Double(i)) : 190 + Double(i))
                }
            }

            // Previous revealed card (visible underneath until the new draw covers it)
            if board.revealed.count >= 2 {
                let prevCard = board.revealed[board.revealed.count - 2]
                Image(uiImage: CardImageCache.shared.image(named: prevCard.id))
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .frame(width: cardWidth, height: cardHeight)
                    .matchedGeometryEffect(id: prevCard.id, in: cardAnimation, isSource: false)
                    .zIndex(299)
            }

            // Revealed (waste) card — with deck-draw flip animation
            if let topCard = board.revealed.last {
                Image(uiImage: CardImageCache.shared.image(named: showDrawnCardFace ? topCard.id : "card0"))
                    .resizable()
                    .interpolation(.medium)
                    .scaledToFit()
                    .frame(width: cardWidth, height: cardHeight)
                    .rotation3DEffect(
                        .degrees(deckDrawAngle),
                        axis: (x: 0, y: 1, z: 0),
                        perspective: 0
                    )
                    .offset(x: deckDrawOffset + (topCard.id == jiggleCardID ? jiggleOffset : 0))
                    .matchedGeometryEffect(id: topCard.id, in: cardAnimation, isSource: false)
                    .zIndex(zIndex(for: topCard.id, base: 300))
            }
        }
    }

    // MARK: - Auto-complete

    private func checkAndStartAutoComplete() {
        guard board.canAutoComplete, !isAutoCompleting, !showAutoCompletePrompt, !board.hasWon else { return }
        showAutoCompletePrompt = true
    }

    private func startAutoComplete() {
        isAutoCompleting = true
        showAutoCompletePrompt = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            autoCompleteNextCard()
        }
    }

    private func autoCompleteNextCard() {
        guard !board.hasWon else {
            isAutoCompleting = false
            return
        }

        guard let nextCard = board.nextAutoCompleteCard() else {
            // No card can currently move to a foundation
            isAutoCompleting = false
            return
        }

        flyingCardID = nextCard.id

        withAnimation(.easeInOut(duration: 0.06)) {
            _ = board.autoCompleteOneCard()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            flyingCardID = nil
            autoCompleteNextCard()
        }
    }

    // MARK: - Celebration Overlay

    var celebrationOverlay: some View {
        ZStack {
            Color.black.opacity(0.75)
                .edgesIgnoringSafeArea(.all)

            VStack(spacing: 16) {
                ZStack {
                    // Glow behind trophy
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [.yellow.opacity(0.6), .clear],
                                center: .center,
                                startRadius: 10,
                                endRadius: 80
                            )
                        )
                        .frame(width: 160, height: 160)

                    Image(systemName: "trophy.fill")
                        .font(.system(size: 72))
                        .foregroundColor(.yellow)
                        .shadow(color: .orange.opacity(0.8), radius: 12)
                }

                Text("YOU WIN!")
                    .font(.system(size: 44, weight: .black, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.5), radius: 4, y: 2)

                Text("Congratulations!")
                    .font(.title3.weight(.medium))
                    .foregroundColor(.white.opacity(0.9))

                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                    Text("Total Wins: \(winCount)")
                        .foregroundColor(.white)
                    Image(systemName: "star.fill")
                        .foregroundColor(.yellow)
                }
                .font(.subheadline.weight(.semibold))
                .padding(.top, 4)

                Button {
                    isAutoCompleting = false
                    showAutoCompletePrompt = false
                    withAnimation(.easeInOut(duration: 0.3)) {
                        showWinCelebration = false
                        board.newGame()
                    }
                } label: {
                    Text("Play Again")
                        .font(.headline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 36)
                        .padding(.vertical, 14)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [.green, .mint],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .shadow(color: .green.opacity(0.5), radius: 8, y: 4)
                }
                .padding(.top, 16)
            }
            .scaleEffect(celebrationScale)
        }
    }

    /// Returns a boosted zIndex for the currently flying card, normal zIndex otherwise
    private func zIndex(for cardID: String, base: Double) -> Double {
        cardID == flyingCardID ? 9999 : base
    }
}

struct BoardView_Previews: PreviewProvider {
    static var previews: some View {
        BoardView(board: .initial())
            .previewInterfaceOrientation(.portrait)
    }
}
