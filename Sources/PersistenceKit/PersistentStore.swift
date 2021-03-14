//
//  PersistentStore.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import CoreData

public final class PersistentStore {
    public enum LoadError : Error {
        case timeout
        case loadErrors(Array<(NSPersistentStoreDescription, Error)>)
    }
    
    internal let container: NSPersistentContainer
    
    public var viewContext: NSManagedObjectContext {
        return self.container.viewContext
    }
    
    public func newBackgroundContext() -> NSManagedObjectContext {
        return self.container.newBackgroundContext()
    }
    
    public func newViewEditingContext() -> NSManagedObjectContext {
        return self.viewContext.createChildContext(concurrencyType: .mainQueueConcurrencyType)
    }
    
    public init(name: String, managedObjectModel model: NSManagedObjectModel) {
        self.container = NSPersistentContainer(name: name, managedObjectModel: model)
    }
    
    public func prepare(withPersistentStoreDescriptions descriptions: Array<NSPersistentStoreDescription>) {
        self.container.persistentStoreDescriptions = descriptions
    }
    
    public func loadStores(timeout: DispatchTime? = nil) throws {
        let waitGroup = DispatchGroup()
        
        for _ in (0..<self.container.persistentStoreDescriptions.count) {
            waitGroup.enter()
        }
        
        let errorQueue = DispatchQueue(label: "dev.schipper.PK.LoadErrorQueue")
        var errors = Array<(NSPersistentStoreDescription, Error)>()
        
        self.container.loadPersistentStores { (desc, err) in
            defer { waitGroup.leave() }
            
            Log.trace("Loaded Persistent Store <\(desc.type)>")
            
            if let error = err {
                errorQueue.sync {
                    errors.append((desc, error))
                }
            }
        }
        
        guard waitGroup.wait(timeout: timeout ?? .now() + .milliseconds(250)) == .success else {
            throw LoadError.timeout
        }
        
        guard errors.count == 0 else {
            throw LoadError.loadErrors(errors)
        }
        
        self.viewContext.automaticallyMergesChangesFromParent = true
    }
    
    public func saveViewContext() throws {
        if self.viewContext.hasChanges {
            try self.viewContext.save()
        }
    }
    
    public func managedObjectID(from uri: URL) -> NSManagedObjectID? {
        return self.container.persistentStoreCoordinator.managedObjectID(forURIRepresentation: uri)
    }
}

extension PersistentStore {
    public func prepareWithInMemoryStore() {
        let desc = NSPersistentStoreDescription()
        desc.type = NSInMemoryStoreType
        desc.shouldAddStoreAsynchronously = false
        
        self.prepare(withPersistentStoreDescriptions: [desc])
    }
}
