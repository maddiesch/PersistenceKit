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

public struct NilContextError : Error {
    
}

extension NSManagedObjectContext {
    public func perform<ResultType>(task: @escaping (NSManagedObjectContext) throws -> ResultType) -> AnyPublisher<ResultType, Error> {
        let publisher = _BackgroundTaskResultPublisher<ResultType>()
        
        self.perform { [weak self] in
            guard let sSelf = self else {
                publisher.fail(NilContextError())
                return
            }
            do {
                let result = try task(sSelf)
                
                publisher.send(result)
            } catch {
                publisher.fail(error)
            }
        }
        
        return publisher.eraseToAnyPublisher()
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
        return self.flatMap { output -> AnyPublisher<Result, Error> in
            return context.perform { (context) -> Result in
                return try block(context, output)
            }
        }.eraseToAnyPublisher()
    }
}

fileprivate class _BackgroundTaskResultPublisher<ResultType> : Publisher {
    typealias Output = ResultType
    
    typealias Failure = Error
    
    private var value: ResultType?
    private var error: Error?
    
    private final class _Subscription : Subscription {
        private var subscriber: AnySubscriber<Output, Failure>?
        private var requested: Subscribers.Demand = .none
        
        init(subscriber: AnySubscriber<Output, Failure>) {
            self.subscriber = subscriber
        }
        
        func request(_ demand: Subscribers.Demand) {
            self.requested += demand
        }
        
        func cancel() {
            self.subscriber = nil
        }
        
        fileprivate func send(_ value: ResultType) {
            defer {
                self.subscriber?.receive(completion: .finished)
            }
            
            guard self.requested > .none else {
                return
            }
            
            self.requested -= .max(1)
            self.requested += self.subscriber?.receive(value) ?? .none
            self.subscriber?.receive(completion: .finished)
        }
        
        fileprivate func fail(_ error: Error) {
            self.subscriber?.receive(completion: .failure(error))
        }
    }
    
    func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = _Subscription(subscriber: AnySubscriber(subscriber))
        
        subscriber.receive(subscription: subscription)
        
        if let v = self.value {
            subscription.send(v)
        } else if let err = self.error {
            subscription.fail(err)
        }
        
        self.receivers.append(subscription)
    }
    
    private var receivers = Array<_Subscription>()
    
    fileprivate func send(_ value: ResultType) {
        self.value = value
        
        for rec in self.receivers {
            rec.send(value)
        }
    }
    
    fileprivate func fail(_ error: Error) {
        self.error = error
        
        for rec in self.receivers {
            rec.fail(error)
        }
    }
}

fileprivate let backgroundTaskReceiverQueue = DispatchQueue(label: PersistenceSubsystemName + ".background-tasks", attributes: .concurrent, autoreleaseFrequency: .workItem)
