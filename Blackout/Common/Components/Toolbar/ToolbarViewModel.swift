//
//  ToolbarViewModel.swift
//  Blackout
//
//  Created by Joses Solmaximo on 24/02/23.
//

import SwiftUI

class ToolbarViewModel: ObservableObject {
    @Published var censorMode: CensorMode = .bar
    @Published var prevCensorMode: CensorMode = .bar
    @Published var textRecognizerMode: TextRecognizerMode = .perLine
    @Published var detectionMode: DetectionMode = .auto
    @Published var manualMode: ManualMode = .draw
    
    @Published var blurRadius = 10
    @Published var pixelScale = 10
    @Published var barColor: Color = .black
    @Published var highlightColor: Color = .yellow.opacity(0.3)
    @Published var underlineColor: Color = .black
    
    @Published var undoCount = 0
    @Published var redoCount = 0
    
    @Published var isRecognizingText = false
    @Published var isOverlayVisible = true
    
    @Published var undoManager = UndoStateManager.shared
    
    func changeIntensity(change: Int){
        if censorMode == .blur {
            if (5...100).contains(blurRadius + change){
                blurRadius += change
            }
        } else if censorMode == .pixel {
            if (5...100).contains(pixelScale + change){
                pixelScale += change
            }
        }
    }
}
