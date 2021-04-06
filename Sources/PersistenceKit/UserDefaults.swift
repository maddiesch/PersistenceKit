//
//  File.swift
//  
//
//  Created by Maddie Schipper on 3/16/21.
//

import Foundation
import CoreData

extension UserDefaults {
    public func setValue(_ value: NSManagedObjectID?, forKey key: String) {
        if let object = value {
            self.setValue(object.uriRepresentation().absoluteString, forKey: key)
        } else {
            self.removeObject(forKey: key)
        }
    }
    
    public func objectID(forKey key: String, inContext context: PersistentContext?) -> NSManagedObjectID? {
        return self.objectID(forKey: key, forCoordinator: context?.persistentStoreCoordinator)
    }
    
    public func objectID(forKey key: String, forCoordinator coordinator: NSPersistentStoreCoordinator?) -> NSManagedObjectID? {
        guard let string = self.string(forKey: key), let uri = URL(string: string) else {
            return nil
        }
        
        return coordinator?.managedObjectID(forURIRepresentation: uri)
    }
}
