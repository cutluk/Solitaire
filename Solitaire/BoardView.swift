//
//  BoardView.swift
//  Solitaire
//
//  Created by Luke Cutting on 7/1/22.
//

import Foundation
import SwiftUI

struct BoardView: View{
    @ObservedObject var board: Board
    var body: some View{
        ZStack{
            Image("background")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            VStack{
                HStack{
                    ForEach(0..<4){ _ in
                        Image("card0")
                            .resizable()
                            .frame(width: 51,height:75)
                            .padding(-14)
                            .padding(.trailing, 23)
                            .padding(.leading, -1)
                    }
        
                    Spacer()
                    Spacer()
                    
                    
                    Image(board.revealed.last?.imageName ?? "card69")
                        .resizable()
                        .frame(width: 51,height:75)
                        .padding(-14)
                        .padding(.trailing, 23)
                        .padding(.leading, -1)
                        .onTapGesture {
                            // reset deck of cards
                           // board.moveAvailable()
                        }
                    
                    Image(board.deck.cards.isEmpty ? "card69" : "card0" )
                        .resizable()
                        .frame(width: 51,height:75)
                        .padding(-14)
                        .onTapGesture {
                            board.reveal()
                        }
        
        
                }
                .padding([.leading, .trailing], 20)
                .padding(.bottom,50)
                .padding(.top,30)
                
                HStack(alignment: .top){                    
                    ForEach(0..<7) { i in
                        VStack{
                            ForEach(board.columns[i]){
                                Image($0.imageName)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 75,height:75)
                                    .padding(.bottom, -50)
                                    .padding([.leading, .trailing],-14)
                                    .onTapGesture {
                                        board.moveAvailable(columnindex: i)
                                    }
                            }
                        }
                    }
                    
              //  Text("\(board.columns[1].count)")
              //  Text("\(board.columns[2][0].value.rawValue) \(board.columns[2][0].suite.rawValue)")
            }
                Spacer()
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
