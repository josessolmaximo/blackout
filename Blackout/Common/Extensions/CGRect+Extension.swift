//
//  CGRect+Extension.swift
//  Blackout
//
//  Created by Joses Solmaximo on 02/03/23.
//

import Foundation

extension CGRect {
    func convert(to bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        var rect = self
        
        rect.origin.x *= imageWidth
        rect.origin.x += bounds.minX
        
        rect.origin.y = (1 - rect.maxY) * imageHeight + bounds.minY
        
        rect.size.width *= imageWidth
        rect.size.height *= imageHeight
        
        return rect
    }
    
    func revert(to bounds: CGRect) -> CGRect {
        let imageWidth = bounds.width
        let imageHeight = bounds.height
        
        var rect = self
        
        rect.origin.x -= bounds.minX
        rect.origin.x /= imageWidth
        
        rect.origin.y = ((bounds.maxY - rect.maxY) - bounds.minY) / imageHeight 
        
        rect.size.width /= imageWidth
        rect.size.height /= imageHeight
        
        return rect
    }
}
