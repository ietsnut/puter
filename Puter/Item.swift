//
//  Item.swift
//  puter
//
//  Created by Marijn Brussel on 04/10/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
