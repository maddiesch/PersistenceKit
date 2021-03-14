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
}
