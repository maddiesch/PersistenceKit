//
//  PersistentViewModel.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import Combine

open class PersistentViewModel<ModelType : PersistentObject> : ObservableObject {
    public private(set) var model: ModelType!
    
    private var modelObserverCanceler: AnyCancellable?
    
    public var cancelers = Set<AnyCancellable>()
    
    public init(model: ModelType) {
        self.model = model
        
        self.modelObserverCanceler = model.managedObjectContext?.objectChangePublisher(objectID: model.objectID).sink(receiveValue: { [weak self] (objectID) in
            if let sSelf = self, let sObjectID = sSelf.model?.objectID, objectID == sObjectID {
                sSelf.objectWillChange.send()
            }
        })
    }
    
    public func update() {
        self.performUpdate()
    }
    
    public func cancel() {
        self.cancelers.cancelAll()
    }
    
    public func willUpdate() {
        self.objectWillChange.send()
    }
    
    open func performUpdate() {
        
    }
    
    deinit {
        self.modelObserverCanceler?.cancel()
        self.modelObserverCanceler = nil
    }
}
