//
//  UndoState.swift
//  Blackout
//
//  Created by Joses Solmaximo on 05/04/23.
//

import SwiftUI

struct UndoState {
    var rects: [TextRect]
    
    init(_ rects: [TextRect]) {
        self.rects = rects
    }
}

class UndoStateManager {
    static let shared = UndoStateManager([])
    
    var rects: [TextRect]
    var undoStack: [(UndoState, UndoState)] = []
    var redoStack: [(UndoState, UndoState)] = []
    
    init(_ rects: [TextRect]) {
        self.rects = rects
    }
    
    func modifyRects(_ newRects: [TextRect]) {
        let currentState = UndoState(rects)
        
        rects = newRects
        
        let newState = UndoState(rects)
        undoStack.append((currentState, newState))
    }
    
    func undo() {
        if let (oldState, newState) = undoStack.popLast() {
            rects = oldState.rects
            redoStack.append((oldState, newState))
        }
    }
    
    func redo() {
        if let (oldState, newState) = redoStack.popLast() {
            rects = newState.rects
            undoStack.append((oldState, newState))
        }
    }
}
