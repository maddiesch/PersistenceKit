//
//  PersistentObjectViewModel.swift
//  
//
//  Created by Maddie Schipper on 3/12/21.
//

import Foundation
import CoreData
import Combine

open class PersistentObjectViewModel<Object : PersistentObject> : ObservableObject {
    private var objectObserverCanceler: AnyCancellable?
    
    public var object: Object {
        didSet {
            self.updateObjectChangeObserver()
        }
    }
    
    public init(object: Object) {
        self.object = object
        
        self.updateObjectChangeObserver()
    }
    
    deinit {
        self.objectObserverCanceler?.cancel()
    }
    
    private func updateObjectChangeObserver() {
        self.objectObserverCanceler?.cancel()
        self.objectObserverCanceler = self.object.objectWillChange.sink { [weak self] in
            self?.objectWillChange.send()
        }
        self.objectDidChange()
    }
    
    open func objectDidChange() {
        
    }
}

open class PersistentObjectContextViewModel<Object : PersistentObject> : PersistentObjectViewModel<Object> {
    public let managedObjectContext: NSManagedObjectContext
    
    public init(object: Object, context: NSManagedObjectContext) {
        self.managedObjectContext = context
        
        super.init(object: object)
    }
    
    private var contextObservers = Set<AnyCancellable>()
    
    public func beginTrackingChanges(forContext context: NSManagedObjectContext) {
        context.publisher(for: \.hasChanges).sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &contextObservers)
    }
    
    public func cancelTrackingObjectContextChanges() {
        self.contextObservers.cancelAll()
    }
    
    deinit {
        self.contextObservers.cancelAll()
    }
}