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
    public let managedObjectContext: PersistentContext!
    
    private var objectObserverCanceler: AnyCancellable?
    
    public var object: Object {
        didSet {
            self.updateObjectChangeObserver()
        }
    }
    
    public init(object: Object) {
        self.object = object
        self.managedObjectContext = object.managedObjectContext
        
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
    private var contextObservers = Set<AnyCancellable>()
    
    public func beginTrackingChanges(forContext context: PersistentContext) {
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
