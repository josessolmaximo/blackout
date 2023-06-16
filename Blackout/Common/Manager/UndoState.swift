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

class UndoStateManager: ObservableObject {
    static let shared = UndoStateManager([])
    
    @Published var rects: [TextRect]
    @Published var undoStack: [(UndoState, UndoState)] = []
    @Published var redoStack: [(UndoState, UndoState)] = []
    
    @Published var toolbarState = ToolbarState()
    @Published var toolbarUndoStack: [(ToolbarState, ToolbarState)] = []
    @Published var toolbarRedoStack: [(ToolbarState, ToolbarState)] = []
    
    @Published var undoCount = 0
    @Published var redoCount = 0
    
    init(_ rects: [TextRect]) {
        self.rects = rects
    }
    
    func modifyRects(_ newRects: [TextRect]) {
        let currentState = UndoState(rects)
        
        rects = newRects
        
        let newState = UndoState(rects)
        undoStack.append((currentState, newState))
        
        undoCount += 1
    }
    
    func undo() {
        if let (oldState, newState) = undoStack.popLast() {
            rects = oldState.rects
            redoStack.append((oldState, newState))
        }
        
        undoCount = undoStack.count
        redoCount = redoStack.count
        print("setrec", undoCount, redoCount)
    }
    
    func redo() {
        if let (oldState, newState) = redoStack.popLast() {
            rects = newState.rects
            undoStack.append((oldState, newState))
        }
        
        undoCount = undoStack.count
        redoCount = redoStack.count
        print("setrec", undoCount, redoCount)
    }
}
