//
//  FetchRequestResultsPublisher.swift
//  
//
//  Created by Maddie Schipper on 3/10/21.
//

import Foundation
import CoreData
import Combine

@available(*, deprecated, message: "Use renamed publisher FetchRequestResultsPublisher")
public typealias FetchResultsPublisher = FetchRequestResultsPublisher

public final class FetchRequestResultsPublisher<ResultType : NSFetchRequestResult> : Publisher {
    public typealias Output = Array<ResultType>
    public typealias Failure = Error
    
    public let fetchRequest: NSFetchRequest<ResultType>
    public let context: PersistentContext
    
    public init(fetchRequest: NSFetchRequest<ResultType>, context: PersistentContext) {
        self.fetchRequest = fetchRequest
        self.context = context
    }
    
    public func receive<S>(subscriber: S) where S : Subscriber, Failure == S.Failure, Output == S.Input {
        let subscription = FetchResultsSubscription(
            subscriber: subscriber,
            fetchRequest: self.fetchRequest,
            context: self.context
        )
        
        subscriber.receive(subscription: subscription)
    }
}

fileprivate final class FetchResultsSubscription<ResultType : NSFetchRequestResult, S : Subscriber> : NSObject, NSFetchedResultsControllerDelegate, Subscription where S.Input == Array<ResultType>, S.Failure == Error {
    let fetchController: NSFetchedResultsController<ResultType>
    
    private var demand: Subscribers.Demand = .unlimited
    
    private var subscriber: S?
    
    private var fetchedObjects: Array<ResultType> {
        return self.fetchController.fetchedObjects ?? []
    }
    
    init(subscriber: S, fetchRequest: NSFetchRequest<ResultType>, context: PersistentContext) {
        self.subscriber = subscriber
        
        self.fetchController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
        
        self.fetchController.delegate = self
    }
    
    func request(_ demand: Subscribers.Demand) {
        self.demand = demand
        
        do {
            Log.debug("Performing Published Fetch <\(String(describing: ResultType.self), privacy: .public)>")
            try self.fetchController.performFetch()
            
            self.updated()
        } catch {
            self.subscriber?.receive(completion: .failure(error))
            self.cancel()
        }
    }
    
    func cancel() {
        self.subscriber = nil
    }
    
    private func updated() {
        guard self.demand > .none else {
            return
        }
        guard let subscriber = self.subscriber else {
            return
        }
        
        self.demand -= .max(1)
        self.demand += subscriber.receive(self.fetchedObjects)
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith diff: CollectionDifference<NSManagedObjectID>) {
        self.updated()
    }
}
