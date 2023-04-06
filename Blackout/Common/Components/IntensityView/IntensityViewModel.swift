//
//  IntensityViewModel.swift
//  Blackout
//
//  Created by Joses Solmaximo on 24/02/23.
//

import Foundation

//class IntensityViewModel: ObservableObject {
//    @Published private(set) var blurRadius = 10
//    @Published private(set) var pixelScale = 10
//
//    @Published private(set) var censorMode: CensorMode = .blur
//
//    func changeIntensity(change: Int){
//        if censorMode == .blur {
//            if (5...100).contains(blurRadius + change){
//                blurRadius += change
//            }
//        } else if censorMode == .pixel {
//            if (5...100).contains(pixelScale + change){
//                pixelScale += change
//            }
//        }
//    }
//
//    func changeCensorMode(censorMode: CensorMode){
//        self.censorMode = censorMode
//    }
//}
