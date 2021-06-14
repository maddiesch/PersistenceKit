//
//  PersistenceKitTests.swift
//
//
//  Created by Maddie Schipper on 3/8/21.
//

import XCTest
import CoreData
@testable import ModelBuilder

fileprivate class Person : NSManagedObject {
    @NSManaged var firstName: String!
    @NSManaged var lastName: String!
    @NSManaged var emails: Set<Email>
}

fileprivate class Email : NSManagedObject {
    @NSManaged var addressValue: String!
    @NSManaged var person: Person!
}

final class ModelBuilderTests: XCTestCase {
    func testModelBuilderDSL() throws {
        let modelBuilder = Model {
            Entity(name: "Person") {
                Attribute(name: "firstName", attributeType: .stringAttributeType).required().validating([
                    (NSPredicate(format: "SELF.length > 0"), "FirstName is required"),
                ])
                Attribute(name: "lastName", attributeType: .stringAttributeType).required().required().validating(
                    .length(min: 1, max: 64, message: "Lastname is required")
                )
                Attribute(name: "isEnabled", attributeType: .booleanAttributeType).required().defaultValue(true)
            }
            .modelClass(Person.self)
            .configuration("InMemory")
            .indexing {
                Index(name: "index-enabled") {
                    Index.Attribute("isEnabled")
                }
            }
            
            Entity(name: "Email") {
                Attribute(name: "addressValue", attributeType: .stringAttributeType).required().defaultValue("").validating(
                    .lengthGreaterThan(min: 5, message: "Email address must be present and longer than 5 characters")
                )
            }
            .modelClass(Email.self)
            .configuration("InMemory")
            
            Entity(name: "Preferences") {
                Attribute(name: "notificationsEnabled", attributeType: .booleanAttributeType).required().defaultValue(true)
            }
            .configuration("InMemory")
        } relationships: {
            Relationship("Person.emails", hasMany: "Email.person")
        }
        
        let container = NSPersistentContainer(name: "Testing", managedObjectModel: modelBuilder.managedObjectModel)
        container.persistentStoreDescriptions.first!.type = NSInMemoryStoreType
        container.persistentStoreDescriptions.first!.configuration = "InMemory"
        
        container.loadPersistentStores { _, error in
            XCTAssertNil(error)
        }
        
        let person = Person(context: container.viewContext)
        person.firstName = "Maddie"
        person.lastName = "Schipper"
        
        let email = Email(context: container.viewContext)
        email.addressValue = "example@example.com"
        email.person = person
        
        try container.viewContext.save()
        
        XCTAssertEqual(person.emails.count, 1)
    }
}
