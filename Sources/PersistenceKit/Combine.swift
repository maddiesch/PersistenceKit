//
//  Combine.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import Combine

extension Set where Element == AnyCancellable {
    internal mutating func cancelAll() {
        for canceler in self {
            canceler.cancel()
        }
        
        self.removeAll()
    }
}
