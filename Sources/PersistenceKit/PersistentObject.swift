//
//  PersistentObject.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import CoreData

open class PersistentObject: NSManagedObject, Identifiable {
    private static let defaultUUID = UUID(uuidString: "05730E76-06D3-4AB9-9E93-BA6B74C9C7F0")!
    
    public enum PersistentKeys : String, CustomStringConvertible {
        case localID = "localID"
        case localCreatedAt = "localCreatedAt"
        case localUpdatedAt = "localUpdatedAt"
        
        public var description: String {
            return self.rawValue
        }
    }
    
    public final class func createdAtSortDescriptor(ascending: Bool = false) -> NSSortDescriptor {
        return NSSortDescriptor(key: PersistentKeys.localCreatedAt.rawValue, ascending: ascending)
    }
    
    public final class func updatedAtSortDescriptor(ascending: Bool = false) -> NSSortDescriptor {
        return NSSortDescriptor(key: PersistentKeys.localUpdatedAt.rawValue, ascending: ascending)
    }
    
    public var id: String {
        return self.localID.uuidString
    }
    
    public class var entityName: String {
        return String(describing: Self.self)
    }
    
    public var localID: UUID! {
        return self.value(forKey: PersistentKeys.localID.rawValue) as? UUID ?? UUID()
    }
    
    public var localCreatedAt: Date! {
        return self.value(forKey: PersistentKeys.localCreatedAt.rawValue) as? Date ?? Date()
    }
    
    public var localUpdatedAt: Date! {
        return self.value(forKey: PersistentKeys.localUpdatedAt.rawValue) as? Date ?? Date()
    }
        
    open override func awakeFromInsert() {
        super.awakeFromInsert()
        
        if let attr = self.entity.attributesByName[PersistentKeys.localID.rawValue], attr.attributeType == .UUIDAttributeType {
            self.setValue(UUID(), forKey: PersistentKeys.localID.rawValue)
        }
        
        if let attr = self.entity.attributesByName[PersistentKeys.localCreatedAt.rawValue], attr.attributeType == .dateAttributeType {
            self.setValue(Date(), forKey: PersistentKeys.localCreatedAt.rawValue)
        }
        
        if let attr = self.entity.attributesByName[PersistentKeys.localUpdatedAt.rawValue], attr.attributeType == .dateAttributeType {
            self.setValue(Date(), forKey: PersistentKeys.localUpdatedAt.rawValue)
        }
    }
    
    open override func willSave() {
        if let attr = self.entity.attributesByName[PersistentKeys.localUpdatedAt.rawValue], attr.attributeType == .dateAttributeType {
            self.setPrimitiveValue(Date(), forKey: PersistentKeys.localUpdatedAt.rawValue)
        }
        
        super.willSave()
    }
    
    open class func configureEntityDescription(_ entityDescription: PersistentEntityDescription) {
        
    }
}

extension PersistentObject {
    public class func createEntityDescription() -> NSEntityDescription {
        let entity = NSEntityDescription()
        entity.name = self.entityName
        entity.managedObjectClassName = NSStringFromClass(Self.self)
        
        entity.addAttribute(PersistentKeys.localID.rawValue, .UUIDAttributeType).require().with(default: PersistentObject.defaultUUID)
        entity.addAttribute(PersistentKeys.localCreatedAt.rawValue, .dateAttributeType).require().with(default: Date(timeIntervalSince1970: 0))
        entity.addAttribute(PersistentKeys.localUpdatedAt.rawValue, .dateAttributeType).require().with(default: Date(timeIntervalSince1970: 0))
        
        entity.unique(PersistentKeys.localID.rawValue)
        
        self.configureEntityDescription(entity)
        
        return entity
    }
}

extension PersistentObject {
    public enum QueryError : Error {
        case objectNotFound(NSManagedObjectID)
    }
    
    public final class func existing(objectWithID objectID: NSManagedObjectID, inContext context: PersistentContext) throws -> Self {
        guard let object = try context.existingObject(with: objectID) as? Self else {
            throw QueryError.objectNotFound(objectID)
        }
        return object
    }
}

public protocol FetchRequestProvider : NSFetchRequestResult {
    static var entityName: String { get }
}

public protocol SortedFetchRequestProvider : FetchRequestProvider {
    static var defaultSortDescriptors: [NSSortDescriptor] { get }
}

extension FetchRequestProvider {
    public static func createFetchRequest(withConfiguration configuration: ((NSFetchRequest<Self>) -> Void)? = nil) -> NSFetchRequest<Self> {
        let fetchRequest = NSFetchRequest<Self>(entityName: self.entityName)
        
        configuration?(fetchRequest)
        
        return fetchRequest
    }
    
    @available(*, deprecated, renamed: "createFetchRequest(withConfiguration:)")
    public static func fetchRequest(configuration: ((NSFetchRequest<Self>) -> Void)? = nil) -> NSFetchRequest<Self> {
        return self.createFetchRequest(withConfiguration: configuration)
    }
}

extension SortedFetchRequestProvider {
    public static func sortedFetchRequest(configuration: ((NSFetchRequest<Self>) -> Void)? = nil) -> NSFetchRequest<Self> {
        let fetchRequest = NSFetchRequest<Self>(entityName: self.entityName)
        fetchRequest.sortDescriptors = self.defaultSortDescriptors
        
        configuration?(fetchRequest)
        
        return fetchRequest
    }
}

extension PersistentObject : FetchRequestProvider {}

extension Set where Element : PersistentObject {
    public mutating func insert(in context: PersistentContext) -> Element {
        let value = Element(context: context)
        
        self.insert(value)
        
        return value
    }
}

extension PersistentContext {
    public func findFirstCreating<Object : PersistentObject>(_ fetchRequest: NSFetchRequest<Object>) throws -> Object {
        precondition(fetchRequest.fetchLimit == 1, "FetchRequest must have a fetchLimit of 1")
        
        return try self.fetch(fetchRequest).first ?? Object(context: self)
    }
}
