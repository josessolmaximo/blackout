//
//  EditorModel.swift
//  Blackout
//
//  Created by Joses Solmaximo on 21/02/23.
//

import SwiftUI

enum CensorMode: String, CaseIterable {
    case bar = "Bar"
    case blur = "Blur"
    case pixel = "Pixel"
    case blend = "Blend"
    case highlight = "Highlight"
    case underline = "Underline"
    
    var image: String {
        switch self {
        case .bar:
            return ""
        case .blur:
            return "drop"
        case .pixel:
            return "checkerboard.rectangle"
        case .blend:
            return "eraser"
        case .highlight:
            return "highlighter"
        case .underline:
            return "underline"
        }
    }
}

enum TextRecognizerMode: String, CaseIterable {
    case perWord = "Detect per Word"
    case perLine = "Detect per Line"
    
    var image: String {
        switch self {
        case .perWord:
            return "textformat.size.larger"
        case .perLine:
            return "textformat.size"
        }
    }
}

enum DetectionMode: String, CaseIterable {
    case auto = "Auto"
    case manual = "Manual"
    
    var image: String {
        switch self {
        case .auto:
            return "wand.and.stars"
        case .manual:
            return "rectangle.dashed"
        }
    }
}

enum EditorMode {
    case auto
    case manual
}

enum ManualMode: String, CaseIterable {
    case draw = "Draw"
    case censor = "Cover"
    case erase = "Erase"
    
    var image: String {
        switch self {
        case .draw:
            return "arrow.up.right.and.arrow.down.left.rectangle"
        case .censor:
            return "checkerboard.rectangle"
        case .erase:
            return "eraser"
        }
    }
}

struct TextRect: Identifiable {
    var id = UUID()
    var rect: CGRect
    var textRecognizerMode: TextRecognizerMode
    var censorMode: CensorMode
    var detectionMode: DetectionMode = .auto
    var color: Color
    var visible: Bool
}

