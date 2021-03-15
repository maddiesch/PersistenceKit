//
//  NSManagedObjectContext.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import CoreData
import Combine

public struct NilContextError : Error, CustomNSError {
    public let message = NSLocalizedString("PersistenceKit.Errors.NilContextDescription", bundle: Bundle.module, comment: "Localized description used when a nil context is returned")
    
    public var errorUserInfo: [String : Any] {
        return [
            NSLocalizedDescriptionKey: self.message
        ]
    }
}

extension NSManagedObjectContext {
    public typealias ManagedObjectContextChangedObjects = (inserted: Array<NSManagedObjectID>, updated: Array<NSManagedObjectID>, delted: Array<NSManagedObjectID>)
    
    public var objectsDidChangePublisher: AnyPublisher<ManagedObjectContextChangedObjects, Never> {
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: self).map { (n) -> ManagedObjectContextChangedObjects in
            let inserted = (n.userInfo?[NSInsertedObjectsKey] as? Array<NSManagedObject> ?? []).map { $0.objectID }
            let updated = (n.userInfo?[NSUpdatedObjectsKey] as? Array<NSManagedObject> ?? []).map { $0.objectID }
            let deleted = (n.userInfo?[NSDeletedObjectsKey] as? Array<NSManagedObject> ?? []).map { $0.objectID }
            
            return ManagedObjectContextChangedObjects(inserted, updated, deleted)
        }.eraseToAnyPublisher()
    }
    
    public func objectChangePublisher(objectID: NSManagedObjectID) -> AnyPublisher<NSManagedObjectID, Never> {
        return self.objectsDidChangePublisher.filter { (results) in
            let (inserted, updated, deleted) = results
            
            return inserted.contains(objectID) || updated.contains(objectID) || deleted.contains(objectID)
        }.flatMap { (_) -> AnyPublisher<NSManagedObjectID, Never> in
            return Just(objectID).eraseToAnyPublisher()
        }.eraseToAnyPublisher()
    }
    
    public func save(propigatingToParent propigate: Bool) throws {
        try self.save()
        
        if propigate, let parent = self.parent {
            try parent.save(propigatingToParent: propigate)
        }
    }
    
    public func createChildContext(concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: concurrencyType)
        context.parent = self
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return context
    }
    
    public func perform<ResultType>(task: @escaping (NSManagedObjectContext) throws -> ResultType) -> Future<ResultType, Error> {
        return Future { finished in
            self.perform { [weak self] in
                do {
                    guard let sSelf = self else {
                        throw NilContextError()
                    }
                    
                    let result = try task(sSelf)
                    
                    finished(.success(result))
                } catch {
                    finished(.failure(error))
                }
            }
        }
    }
}
