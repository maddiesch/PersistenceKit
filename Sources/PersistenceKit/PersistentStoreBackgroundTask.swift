//
//  PersistentStoreBackgroundTask.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation
import CoreData
import Combine

extension PersistentStore {
    public func performInBackgroundContext<ResultType>(task: @escaping (NSManagedObjectContext) throws -> ResultType) -> AnyPublisher<ResultType, Error> {
        let context = self.newBackgroundContext()
        
        return context.perform(task: task).receive(on: backgroundTaskReceiverQueue).eraseToAnyPublisher()
    }
}

extension Publisher {
    public func inBackgroundContext<Result>(for store: PersistentStore, block: @escaping (NSManagedObjectContext, Self.Output) throws -> Result) -> AnyPublisher<Result, Error> where Self.Failure == Error {
        return Publishers.FlatMap(upstream: self, maxPublishers: .unlimited) { output -> AnyPublisher<Result, Error> in
            return store.performInBackgroundContext { (context) -> Result in
                return try block(context, output)
            }
        }.eraseToAnyPublisher()
    }
    
    public func inContext<Result>(for context: NSManagedObjectContext, block: @escaping (NSManagedObjectContext, Self.Output) throws -> Result) -> AnyPublisher<Result, Error> where Self.Failure == Error {
        return self.flatMap { output -> Future<Result, Error> in
            return context.perform { (context) -> Result in
                return try block(context, output)
            }
        }.eraseToAnyPublisher()
    }
}

fileprivate let backgroundTaskReceiverQueue = DispatchQueue(label: PersistenceSubsystemName + ".background-tasks", attributes: .concurrent, autoreleaseFrequency: .workItem)
