//
//  PersistenceKitTests.swift
//
//
//  Created by Maddie Schipper on 3/8/21.
//

import XCTest
@testable import PersistenceKit

final class PersistenceKitTests: XCTestCase {
    func testPersistentStoreSetup() throws {
        let store = PersistentStore(name: "Testing", managedObjectModel: CreateManagedObjectModel())
        store.prepareWithInMemoryStore()
        
        try store.loadStores()
    }
    
    func testFetchRequestResultsPublisher() throws {
        let store = PersistentStore(name: "Testing", managedObjectModel: CreateManagedObjectModel())
        store.prepareWithInMemoryStore()
        try store.loadStores()
        
        let fetchRequest = Person.fetchRequest {
            $0.sortDescriptors = [NSSortDescriptor(key: "firstName", ascending: true)]
        }
        
        let expectation = self.expectation(description: "wait for fetch")
        expectation.expectedFulfillmentCount = 2
        
        let cancelable = FetchRequestResultsPublisher(fetchRequest: fetchRequest, context: store.viewContext).sink { (completion) in
            
        } receiveValue: { (_) in
            expectation.fulfill()
        }
        
        let background = store.container.newBackgroundContext()
        background.perform {
            let person = Person(context: background)
            person.firstName = "Madison"
            person.lastName = "Schipper"
            
            try? background.save()
        }

        self.wait(for: [expectation], timeout: 1)
        
        cancelable.cancel()
    }
}
