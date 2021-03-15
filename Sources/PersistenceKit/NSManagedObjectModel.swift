//
//  NSManagedObjectModel.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import CoreData

extension NSManagedObjectModel {
    @discardableResult
    public func register(persitentObjectClass klass: PersistentObject.Type) -> NSEntityDescription {
        let entity = klass.createEntityDescription()
        
        self.entities.append(entity)
        
        return entity
    }
}

extension NSEntityDescription {
    @discardableResult
    public func addAttribute(_ name: String, _ type: NSAttributeType) -> NSAttributeDescription {
        let property = NSAttributeDescription()
        property.name = name
        property.attributeType = type
        property.isOptional = true
        
        self.properties.append(property)
        
        return property
    }
    
    public func unique(_ names: String...) {
        self.uniquenessConstraints.append(names)
    }
    
    public func index(propertyWithName name: String) {
        self.index(propertiesWithNames: [name])
    }
    
    public func index(propertiesWithNames names: String...) {
        self.index(propertiesWithNames: names)
    }
    
    public func index(propertiesWithNames names: Array<String>) {
        let elements = names.map { name -> NSFetchIndexElementDescription in
            guard let property = self.propertiesByName[name] else {
                fatalError("Failed to find a property with the given name: \(name)")
            }
            
            return NSFetchIndexElementDescription(property: property, collationType: .binary)
        }
        
        self.index(name: "\(self.name ?? "_UNKNOWN_")_index_\(names.joined(separator: "_"))", elements: elements)
    }
    
    public func index(property: NSPropertyDescription) {
        self.index(name: "\(self.name ?? "_UNKNOWN_")_index_\(property.name)", elements: [
            NSFetchIndexElementDescription(property: property, collationType: .binary)
        ])
    }
    
    public func index(name: String, elements: Array<NSFetchIndexElementDescription>) {
        let index = NSFetchIndexDescription(name: name, elements: elements)
        
        self.indexes.append(index)
    }
    
    public func belongsTo(_ destination: NSEntityDescription, property: String, inverse: String, isRequired: Bool = true, deleteRule: NSDeleteRule = .nullifyDeleteRule, inverseDeleteRule: NSDeleteRule = .nullifyDeleteRule) {
        let source = NSRelationshipDescription()
        source.destinationEntity = destination
        source.name = property
        source.deleteRule = deleteRule
        source.maxCount = 1
        source.minCount = isRequired ? 1 : 0
        
        let dest = NSRelationshipDescription()
        dest.destinationEntity = self
        dest.name = inverse
        dest.deleteRule = inverseDeleteRule
        dest.minCount = 0
        dest.maxCount = 0
        
        source.inverseRelationship = dest
        dest.inverseRelationship = source
        
        self.properties.append(source)
        destination.properties.append(dest)
    }
    
    @discardableResult
    public func hasMany(_ destination: NSEntityDescription, property: String, inverse: String, deleteRule: NSDeleteRule = .nullifyDeleteRule, inverseDeleteRule: NSDeleteRule = .nullifyDeleteRule) -> (NSRelationshipDescription, NSRelationshipDescription) {
        let source = NSRelationshipDescription()
        source.destinationEntity = destination
        source.name = property
        source.deleteRule = deleteRule
        source.maxCount = 0
        source.minCount = 0
        
        let dest = NSRelationshipDescription()
        dest.destinationEntity = self
        dest.name = inverse
        dest.deleteRule = inverseDeleteRule
        dest.minCount = 0
        dest.maxCount = 1
        
        source.inverseRelationship = dest
        dest.inverseRelationship = source
        
        self.properties.append(source)
        destination.properties.append(dest)
        
        return (source, dest)
    }
    
    @discardableResult
    public func hasAndBelongsToMany(_ destination: NSEntityDescription, property: String, inverse: String, deleteRule: NSDeleteRule = .nullifyDeleteRule, inverseDeleteRule: NSDeleteRule = .nullifyDeleteRule) -> (NSRelationshipDescription, NSRelationshipDescription) {
        let source = NSRelationshipDescription()
        source.destinationEntity = destination
        source.name = property
        source.deleteRule = deleteRule
        source.maxCount = 0
        source.minCount = 0
        
        let dest = NSRelationshipDescription()
        dest.destinationEntity = self
        dest.name = inverse
        dest.deleteRule = inverseDeleteRule
        dest.minCount = 0
        dest.maxCount = 0
        
        source.inverseRelationship = dest
        dest.inverseRelationship = source
        
        self.properties.append(source)
        destination.properties.append(dest)
        
        return (source, dest)
    }
}

extension NSAttributeDescription {
    @discardableResult
    public func with(default value: Any?) -> NSAttributeDescription {
        self.defaultValue = value
        
        return self
    }
    
    @discardableResult
    public func validated(by validators: Array<Validates.Predicate>) -> NSAttributeDescription {
        var predicates = Array<NSPredicate>()
        var messages = Array<String>()
        
        for (predicate, message) in validators {
            predicates.append(predicate)
            messages.append(message)
        }
        
        self.setValidationPredicates(predicates, withValidationWarnings: messages)
        
        return self
    }
    
    @discardableResult
    public func require() -> NSAttributeDescription {
        self.isOptional = false
        
        return self
    }
    
    @discardableResult
    public func storeExternally() -> NSAttributeDescription {
        self.allowsExternalBinaryDataStorage = true
        
        return self
    }
}

public struct Validates {
    public typealias Predicate = (NSPredicate, String)
    
    public enum Comparitor : String {
        case equal = "="
        case greaterThan = ">"
        case greaterThanOrEqualTo = ">="
        case lessThan = "<"
        case lessThanOrEqualTo = "<="
    }
    
    public static func `is`<T : CVarArg>(_ comparator: Comparitor, object: T, message: String) -> Predicate {
        return (NSPredicate(format: "SELF \(comparator.rawValue) %@", object), message)
    }
    
    public static func `is`<T : FixedWidthInteger>(_ comparator: Comparitor, value: T, message: String) -> Predicate {
        return (NSPredicate(format: "SELF \(comparator.rawValue) %d", value as! CVarArg), message)
    }
    
    public static func length(is comparitor: Comparitor = .greaterThan, length: Int = 0, message: String) -> Predicate {
        return (NSPredicate(format: "SELF.length \(comparitor.rawValue) %d", length), message)
    }
}

extension NSManagedObjectID : Identifiable {
    public var id: NSManagedObjectID {
        return self
    }
}
