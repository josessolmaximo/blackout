//
//  CGPoint+Extension.swift
//  Blackout
//
//  Created by Joses Solmaximo on 02/03/23.
//

import Foundation

extension CGPoint : Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x)
        hasher.combine(y)
    }
}
