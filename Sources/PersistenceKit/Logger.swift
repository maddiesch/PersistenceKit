//
//  Logger.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import OSLog

internal let PersistenceSubsystemName: String = {
    if let identifier = Bundle.main.bundleIdentifier {
        return identifier
    }
    return "dev.schipper.PersistenceKit-Subsystem"
}()

internal let Log = Logger(subsystem: PersistenceSubsystemName, category: "Persistence")
