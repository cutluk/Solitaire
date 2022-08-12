//
//  ContentView.swift
//  Solitaire
//
//  Created by Luke Cutting on 5/15/22.
//

import SwiftUI

struct ContentView: View {
    
    
    @State var dealtCard:Int = 69
    @State var rand = Int.random(in: 1...52)
    var column1 = Array(repeating: 5, count: 15)
    var column2 = Array(repeating: 4, count: 15)
    var column3 = Array(repeating: 0, count: 15)
    var column4 = Array(repeating: 0, count: 15)
    var column5 = Array(repeating: 0, count: 15)
    var column6 = Array(repeating: 0, count: 15)
    var column7 = Array(repeating: 0, count: 15)
    
   
    
    var body: some View {
        
        
        ZStack{
            Image("background")
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            
            VStack{

                Image(Card(value: .eight, suite: .clubs).imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 75,height:75)
                
                HStack{
                  
//                    Image("card0").resizable()
//                        .scaledToFit()
//                        .frame(width: 10,height:10).padding(-2.0)
//                    Image("card0").resizable()
//                        .scaledToFit()
//                        .frame(width: 75,height:75).padding(-2.0)
//                    Image("card0").resizable()
//                        .scaledToFit()
//                        .frame(width: 75,height:75).padding(-2.0)
//                    Image("card0").resizable()
//                        .scaledToFit()
//                        .frame(width: 75,height:75).padding(-2.0)
                    Spacer()
                    Spacer()
                //    Image("card"+String(dealtCard)).padding(-2.0)
                    
                    Button(action: {self.dealtCard = Int.random(in: 1...52)
                    }){
                        Image("card0").resizable()
                            .scaledToFit()
                            .frame(width: 75,height:75).padding(-2.0)
                    }
        
                }
                    .padding([.leading, .trailing], 10)
                    .padding(.bottom,50)
                    .padding(.top,30)
                
                HStack{
                    VStack{
//                        Image("card" + String(column1[0])).padding(.bottom, -50)
//                        Image("card"+String(column1[1])).padding(.bottom, -50)
//                        Image("card0").padding(.bottom, -50)
//                        Image("card0").padding(.bottom, -50)
//                        Image("card0").padding(.bottom, -50)
                    }
                    VStack{
//                        Image("card" + String(column1[0])).padding(.bottom, -50)
//                        Image("card"+String(column1[1])).padding(.bottom, -50)
//                        Image("card0").padding(.bottom, -50)
//                        Image("card0").padding(.bottom, -50)
                    }
                }
                
               
                
                Spacer()
                
            
                
            }
           
        }
       
    }
   
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(dealtCard: 69)
    }
}
