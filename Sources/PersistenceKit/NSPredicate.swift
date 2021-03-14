//
//  NSPredicate.swift
//  
//
//  Created by Maddie Schipper on 3/9/21.
//

import Foundation

extension NSPredicate {
    public static func and(_ predicates: NSPredicate...) -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
    }
}
