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
    @Published var detectionMode: DetectionMode = .auto
    @Published var manualMode: ManualMode = .draw
    
    @Published var toolbarState = ToolbarState()
    
    @Published var barColor: Color = .black
    @Published var highlightColor: Color = .yellow.opacity(0.3)
    @Published var underlineColor: Color = .black
    
    @Published var undoCount = 1
    @Published var redoCount = 0
    
    @Published var isRecognizingText = false
    
    @Published var undoManager = UndoStateManager.shared
    
    func changeIntensity(change: Int){
        if censorMode == .blur {
            if (5...100).contains(toolbarState.blurRadius + change){
                toolbarState.blurRadius += change
            }
        } else if censorMode == .pixel {
            if (5...100).contains(toolbarState.pixelScale + change){
                toolbarState.pixelScale += change
            }
        }
    }
}
