//
//  ToolbarModel.swift
//  Blackout
//
//  Created by Joses Solmaximo on 24/02/23.
//

import Foundation

struct ToolbarState {
    var textRecognizerMode: TextRecognizerMode = .perLine
    
    var blurRadius = 10
    var pixelScale = 10
    
    var isOverlayVisible = true
}
