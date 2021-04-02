//
//  PersistentObjectFetchedView.swift
//  
//
//  Created by Maddie Schipper on 3/10/21.
//

#if canImport(SwiftUI)
import SwiftUI
import CoreData
import Combine

@available(*, deprecated, message: "Use FetchedResultsPublisher in your own view instead")
public struct PersistentObjectFetchedView<ObjectType : PersistentObject, Content : View> : View {
    private let publisher: AnyPublisher<Array<ObjectType>, Never>
    private let content: (Array<ObjectType>) -> Content
    
    @State private var results: Array<ObjectType> = []
    
    public init(fetchRequest: NSFetchRequest<ObjectType>, context: NSManagedObjectContext, @ViewBuilder content: @escaping (Array<ObjectType>) -> Content) {
        self.content = content
        self.publisher = FetchRequestResultsPublisher(fetchRequest: fetchRequest, context: context).replaceError(with: []).eraseToAnyPublisher()
    }
    
    public var body: some View {
        return ZStack {
            self.content(self.results)
        }.onReceive(self.publisher, perform: { results in
            self.results = results
        })
    }
}

#endif
