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

extension PersistentContext {
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
    
    public func createChildContext(concurrencyType: NSManagedObjectContextConcurrencyType = .mainQueueConcurrencyType) -> PersistentContext {
        let context = PersistentContext(concurrencyType: concurrencyType)
        context.parent = self
        context.automaticallyMergesChangesFromParent = true
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        return context
    }
    
    public func performWithErrorHandler(task: @escaping (PersistentContext) throws -> Void) -> Future<Error?, Never> {
        return Future { finished in
            self.perform { [weak self] in
                guard let sSelf = self else {
                    finished(.success(NilContextError()))
                    return
                }
                
                do {
                    try task(sSelf)
                    
                    finished(.success(nil))
                } catch {
                    finished(.success(error))
                }
            }
        }
    }
    
    public func perform<ResultType>(task: @escaping (PersistentContext) throws -> ResultType) -> Future<ResultType, Error> {
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
    
    public var contextChangedPublisher: AnyPublisher<PersistentContext, Never> {
        return NotificationCenter.default.publisher(for: .NSManagedObjectContextObjectsDidChange, object: self).filter { notification in
            guard let context = notification.object as? PersistentContext else {
                return false
            }
            return context.hasChanges
        }.compactMap {
            return $0.object as? PersistentContext
        }.eraseToAnyPublisher()
    }
    
    public func createChangePublisher<S : Scheduler>(timeInterval: S.SchedulerTimeType.Stride, scheduler: S) -> AnyPublisher<PersistentContext, Never> {
        return self.contextChangedPublisher.throttle(for: timeInterval, scheduler: scheduler, latest: true).eraseToAnyPublisher()
    }
}

extension PersistentContext {
    @discardableResult
    public func delete(objectsWithIDs objectIDs: Set<PersistentObjectID>) throws -> Int {
        let batchDelete = NSBatchDeleteRequest(objectIDs: objectIDs.map { $0 })
        batchDelete.resultType = .resultTypeCount
        
        let deleteResult = try self.execute(batchDelete) as? NSBatchDeleteResult
        
        return deleteResult?.result as? Int ?? -1
    }
}
