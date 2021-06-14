//
//  ModelBuilder.swift
//  
//
//  Created by Maddie Schipper on 6/11/21.
//

import CoreData

/// Resource provides a standard protocol for a ModelBuilder
public protocol Resource {
    /// The type of object the resource should be applied to
    associatedtype ApplicationType
    
    /// Apply the resource to the given object
    func apply(to: inout ApplicationType)
}

/// Model provides the constructor for building a NSManagedObjectModel
public struct Model {
    /// The constructed managed object model
    public let managedObjectModel: NSManagedObjectModel

    /// Create a model with enties and optional relationships
    /// - Parameters:
    ///   - entities: The list of entities the apply to the model
    ///   - relationships: The list of relationships for entities
    public init(@ModelBuilder entities: () -> [Entity], @ModelBuilder relationships: () -> [Relationship] = { [] }) {
        var model = NSManagedObjectModel()
        
        for entity in entities() {
            entity.apply(to: &model)
        }
        
        for relationship in relationships() {
            relationship.apply(to: &model)
        }
        
        self.init(model)
    }
    
    private init(_ mom: NSManagedObjectModel) {
        self.managedObjectModel = mom
    }

    /// Allow custom configuration of the NSManagedObjectModel
    /// - Parameter config: The configuration block
    /// - Returns: The Model with the newly configured NSManagedObjectModel
    public func configureManagedObjectModel(config: (inout NSManagedObjectModel) -> Void) -> Model {
        var managedObjectModel = self.managedObjectModel
        
        config(&managedObjectModel)
        
        return Model(managedObjectModel)
    }
}


/// Provides the interface for building a Model
@resultBuilder public enum ModelBuilder { }

/// Defines a NSEntityDescription
public struct Entity : Resource {
    fileprivate let entity: NSEntityDescription
    fileprivate let configurations: Set<String>

    /// Create a new Entity
    /// - Parameters:
    ///   - name: The name of the entity
    ///   - builder: The block what handles building the entity attributes
    public init(name: String, @ModelBuilder builder: () -> NSEntityDescription) {
        let entity = builder()
        entity.name = name
        
        self.init(entity: entity, configurations: [])
    }
    
    fileprivate init(entity: NSEntityDescription, configurations: Set<String>) {
        self.entity = entity
        self.configurations = configurations
    }
    
    public func apply(to model: inout NSManagedObjectModel) {
        model.entities.append(entity)
        
        for configurationName in self.configurations {
            var entities = model.entities(forConfigurationName: configurationName) ?? []
            entities.append(entity)
            model.setEntities(entities, forConfigurationName: configurationName)
        }
    }
    
    public func configuration(_ name: String) -> Entity {
        var configurations = self.configurations
        configurations.insert(name)
        
        return Entity(entity: self.entity, configurations: configurations)
    }
    
    public func modelClass<T : NSManagedObject>(_ type: T.Type) -> Entity {
        let entity = self.entity
        entity.managedObjectClassName = NSStringFromClass(type.self)
        return Entity(entity: entity, configurations: self.configurations)
    }
    
    public func unique(_ propertyNames: String...) -> Entity {
        let entity = self.entity
        entity.uniquenessConstraints.append(propertyNames)
        return Entity(entity: entity, configurations: self.configurations)
    }
}

extension ModelBuilder {
    public static func buildBlock(_ components: Entity...) -> [Entity] {
        return components
    }
}

// MARK: - Entity/Attribute

public struct Attribute : Resource {
    private let attribute: NSAttributeDescription
    
    public init(name: String, attributeType: NSAttributeType) {
        let attribute = NSAttributeDescription()
        attribute.name = name
        attribute.attributeType = attributeType
        
        self.init(attribute: attribute)
    }
    
    public init(attribute: NSAttributeDescription) {
        self.attribute = attribute
    }
    
    public func apply(to entity: inout NSEntityDescription) {
        entity.properties.append(attribute)
    }
    
    public func defaultValue(_ value: Any?) -> Attribute {
        let attribute = self.attribute
        attribute.defaultValue = value
        return Attribute(attribute: attribute)
    }
    
    public func required(required isRequired: Bool = true) -> Attribute {
        let attribute = self.attribute
        attribute.isOptional = !isRequired
        return Attribute(attribute: attribute)
    }
    
    public func validating(_ validations: Validation...) -> Attribute {
        return self.validating(validations)
    }
    
    public func validating(_ validations: [Validation]) -> Attribute {
        return validating(validations.map(\.validator))
    }
    
    public func validating(_ validations: [(NSPredicate, String)]) -> Attribute {
        var predicates = Array<NSPredicate>()
        var messages = Array<String>()
        
        let attribute = self.attribute
        
        for (predicate, message) in validations {
            predicates.append(predicate)
            messages.append(message)
        }
        
        attribute.setValidationPredicates(predicates, withValidationWarnings: messages)
        
        return Attribute(attribute: attribute)
    }
}

public enum Validation {
    /// Verify the length of the value is greater and or equal to the minimum and less than or equal to the maximum
    case length(min: Int, max: Int, message: String)

    /// Verify the length is greater than or equal to the minimum
    case lengthGreaterThan(min: Int, message: String)

    /// Verify the length is less than or equal to the maximum
    case lengthLessThan(max: Int, message: String)

    /// Ensures the value has the given string prefix
    case hasPrefix(prefix: String, message: String)

    /// Ensures the value has the given string suffix
    case hasSuffix(suffix: String, message: String)

    /// Provide a custom predicate for validation
    case custom(format: String, args: [CVarArg], message: String)
    
    fileprivate var validator: (NSPredicate, String) {
        switch self {
        case .length(let minimum, let maximum, let message):
            return (NSPredicate(format: "SELF.length BETWEEN {%ld, %ld}", minimum, maximum), message)
        case .lengthGreaterThan(let minimum, let message):
            return (NSPredicate(format: "SELF.length >= %ld", minimum), message)
        case .lengthLessThan(let maximum, let message):
            return (NSPredicate(format: "SELF.length <= %ld", maximum), message)
        case .hasPrefix(let value, let message):
            return (NSPredicate(format: "SELF BEGINSWITH %@", value), message)
        case .hasSuffix(let value, let message):
            return (NSPredicate(format: "SELF ENDSWITH %@", value), message)
        case .custom(let format, let args, let message):
            return (NSPredicate(format: format, argumentArray: args), message)
        }
    }
}

extension ModelBuilder {
    public static func buildBlock(_ components: Attribute...) -> NSEntityDescription {
        var entity = NSEntityDescription()
        
        for resource in components {
            resource.apply(to: &entity)
        }
        
        return entity
    }
}

// MARK: - Entity/Index

public struct Index {
    public struct Attribute {
        fileprivate let name: String
        fileprivate let collationType: NSFetchIndexElementType
        
        public init(_ name: String, collationType: NSFetchIndexElementType = .binary) {
            self.name = name
            self.collationType = collationType
        }
    }
    
    private let name: String
    private let attributes: [Index.Attribute]
    
    public init(name: String, @ModelBuilder builder: () -> [Index.Attribute]) {
        self.name = name
        self.attributes = builder()
    }
    
    fileprivate func apply(to entity: NSEntityDescription) {
        precondition(self.attributes.count > 0)
        
        let description = NSFetchIndexDescription()
        description.name = self.name
        
        for attr in self.attributes {
            guard let property = entity.propertiesByName[attr.name] else {
                fatalError("Failed to find attribute with the name \(attr.name) on \(entity.name ?? "<unknown>")")
            }
            let element = NSFetchIndexElementDescription(property: property, collationType: attr.collationType)
            
            description.elements.append(element)
        }
        
        entity.indexes.append(description)
    }
}

extension Entity {
    public func indexing(@ModelBuilder builder: () -> [Index]) -> Entity {
        let entity = self.entity
        
        for index in builder() {
            index.apply(to: entity)
        }
        
        return Entity(entity: entity, configurations: self.configurations)
    }
}

extension ModelBuilder {
    public static func buildBlock(_ components: Index...) -> [Index] {
        return components
    }
}

extension ModelBuilder {
    @available(*, unavailable, message: "At least one attribute must be specified for an index")
    public static func buildBlock(_ components: Index.Attribute...) -> [Index.Attribute] {
        fatalError()
    }
    
    public static func buildBlock(_ first: Index.Attribute, _ components: Index.Attribute...) -> [Index.Attribute] {
        return [first] + components
    }
}

// MARK: - Relationships

public enum Relationship {
    public typealias Source = (entityName: String, propertyName: String)
    
    case hasMany(source: Source, destination: Source, sourceDeleteRule: NSDeleteRule, destinationDeleteRule: NSDeleteRule)
    case hasOne(source: Source, destination: Source, sourceDeleteRule: NSDeleteRule, destinationDeleteRule: NSDeleteRule)
    
    public init(_ sourcePath: String, hasMany destinationPath: String) {
        precondition(sourcePath.contains("."))
        precondition(destinationPath.contains("."))
        
        let sourceParts = sourcePath.split(separator: ".", maxSplits: 2)
        let destinationParts = destinationPath.split(separator: ".", maxSplits: 2)
        
        let source = Source(entityName: String(sourceParts[0]), propertyName: String(sourceParts[1]))
        let destination = Source(entityName: String(destinationParts[0]), propertyName: String(destinationParts[1]))
        
        self.init(source, hasMany: destination)
    }
    
    public init(_ sourcePath: String, hasOne destinationPath: String) {
        precondition(sourcePath.contains("."))
        precondition(destinationPath.contains("."))
        
        let sourceParts = sourcePath.split(separator: ".", maxSplits: 2)
        let destinationParts = destinationPath.split(separator: ".", maxSplits: 2)
        
        let source = Source(entityName: String(sourceParts[0]), propertyName: String(sourceParts[1]))
        let destination = Source(entityName: String(destinationParts[0]), propertyName: String(destinationParts[1]))
        
        self.init(source, hasOne: destination)
    }
    
    public init(_ source: Source, hasMany: Source) {
        self = .hasMany(source: source, destination: hasMany, sourceDeleteRule: .cascadeDeleteRule, destinationDeleteRule: .nullifyDeleteRule)
    }
    
    public init(_ source: Source, hasOne: Source) {
        self = .hasOne(source: source, destination: hasOne, sourceDeleteRule: .cascadeDeleteRule, destinationDeleteRule: .nullifyDeleteRule)
    }
    
    fileprivate func apply(to model: inout NSManagedObjectModel) {
        switch self {
        case .hasMany(let sourceInfo, let destinationInfo, let sourceDeleteRule, let destinationDeleteRule):
            let (source, destination) = createRelationshipDestriptions(model, sourceInfo, destinationInfo, sourceDeleteRule, destinationDeleteRule)
            
            source.minCount = 0
            source.maxCount = 0
            destination.minCount = 1
            destination.maxCount = 1
        case .hasOne(let sourceInfo, let destinationInfo, let sourceDeleteRule, let destinationDeleteRule):
            let (source, destination) = createRelationshipDestriptions(model, sourceInfo, destinationInfo, sourceDeleteRule, destinationDeleteRule)
            
            source.minCount = 0
            source.maxCount = 1
            destination.minCount = 1
            destination.maxCount = 1
        }
    }
    
    private func createRelationshipDestriptions(_ model: NSManagedObjectModel, _ sourceInfo: Source, _ destinationInfo: Source, _ sourceDeleteRule: NSDeleteRule, _ destinationDeleteRule: NSDeleteRule) -> (NSRelationshipDescription, NSRelationshipDescription) {
        let source = NSRelationshipDescription()
        let destination = NSRelationshipDescription()
        source.inverseRelationship = destination
        destination.inverseRelationship = source
        
        guard let sourceEntity = model.entitiesByName[sourceInfo.entityName], let destinationEntity = model.entitiesByName[destinationInfo.entityName] else {
            fatalError("Failed to find entities for relationship \(sourceInfo.entityName) <->> \(destinationInfo.entityName)")
        }
        
        source.name = sourceInfo.propertyName
        source.destinationEntity = destinationEntity
        source.deleteRule = sourceDeleteRule
        
        destination.name = destinationInfo.propertyName
        destination.destinationEntity = sourceEntity
        destination.deleteRule = destinationDeleteRule
        
        sourceEntity.properties.append(source)
        destinationEntity.properties.append(destination)
        
        return (source, destination)
    }
}

extension ModelBuilder {
    public static func buildBlock(_ components: Relationship...) -> [Relationship] {
        return components
    }
}
