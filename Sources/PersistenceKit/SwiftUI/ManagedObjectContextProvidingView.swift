//
//  ManagedObjectContextProvidingView.swift
//  
//
//  Created by Maddie Schipper on 3/24/21.
//

import SwiftUI
import CoreData

public struct ManagedObjectContextProvidingView<Content : View> : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    let content: (NSManagedObjectContext) -> Content
    
    public init(@ViewBuilder content: @escaping (NSManagedObjectContext) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        return self.content(managedObjectContext)
    }
}
