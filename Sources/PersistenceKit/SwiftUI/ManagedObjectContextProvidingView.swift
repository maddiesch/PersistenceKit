//
//  ManagedObjectContextProvidingView.swift
//  
//
//  Created by Maddie Schipper on 3/24/21.
//

import SwiftUI

public struct ManagedObjectContextProvidingView<Content : View> : View {
    @Environment(\.managedObjectContext) var managedObjectContext
    
    let content: (PersistentContext) -> Content
    
    public init(@ViewBuilder content: @escaping (PersistentContext) -> Content) {
        self.content = content
    }
    
    public var body: some View {
        return self.content(managedObjectContext)
    }
}
