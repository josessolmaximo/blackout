//
//  CGImage+Extension.swift
//  Blackout
//
//  Created by Joses Solmaximo on 02/03/23.
//

import UIKit
import CoreImage

extension CGImage {
    func getPixelColors(rects: [TextRect], imageRect: CGRect) -> [UUID: UIColor]? {
        var colors: [UUID: UIColor] = [:]
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8
        let bitmapInfo: UInt32 = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
        
        guard let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
              let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return nil
        }
        
        context.draw(self, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        for rect in rects {
            if rect.censorMode == .blend {
                let box = rect.rect.convert(to: imageRect)
                
                let topLeft = CGPoint(x: box.minX, y: box.minY)
                let topRight = CGPoint(x: box.maxX, y: box.minY)
                
                let topCenter = CGPoint(x: box.midX, y: box.minY)
                let bottomCenter = CGPoint(x: box.midX, y: box.maxY)
                
                let centerLeft = CGPoint(x: box.minX, y: box.midY)
                let centerRight = CGPoint(x: box.maxX, y: box.midY)
                
                let bottomLeft = CGPoint(x: box.minX, y: box.maxY)
                let bottomRight = CGPoint(x: box.maxX, y: box.maxY)
                
                var cornerColors: [UIColor] = []
                
                for corner in [topLeft, topRight, bottomLeft, bottomRight, topCenter, bottomCenter, centerLeft, centerRight] {
                    let i = bytesPerRow * Int(corner.y) + bytesPerPixel * Int(corner.x)
                    
                    let a = CGFloat(ptr[i + 3]) / 255.0
                    let r = (CGFloat(ptr[i]) / a) / 255.0
                    let g = (CGFloat(ptr[i + 1]) / a) / 255.0
                    let b = (CGFloat(ptr[i + 2]) / a) / 255.0
                    
                    cornerColors.append(UIColor(red: r, green: g, blue: b, alpha: a))
                }
                
                let countedSet = NSCountedSet(array: cornerColors)
                let mostFrequent = countedSet.max { countedSet.count(for: $0) < countedSet.count(for: $1) }
                
                colors[rect.id] = (mostFrequent as! UIColor)
            }
        }
        
        return colors
    }
}
