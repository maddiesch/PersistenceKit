//
//  ManagedObjectModel.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import CoreData

import PersistenceKit

class Person : PersistentObject {
    @NSManaged var firstName: String?
    @NSManaged var lastName: String?
    
    override class func configureEntityDescription(_ entityDescription: NSEntityDescription) {
        entityDescription.addAttribute("firstName", .stringAttributeType)
        entityDescription.addAttribute("lastName", .stringAttributeType)
    }
}

func CreateManagedObjectModel() -> NSManagedObjectModel {
    let model = NSManagedObjectModel()
    
    let personEntity = Person.createEntityDescription()
    
    model.entities.append(personEntity)
    
    return model
}
