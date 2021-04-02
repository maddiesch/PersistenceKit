//
//  FetchControllerProviderView.swift
//  
//
//  Created by Maddie Schipper on 3/8/21.
//

import Foundation

#if canImport(SwiftUI)
import CoreData
import SwiftUI

@available(*, deprecated, message: "Use FetchedResultsPublisher in your own view instead")
public struct FetchControllerProviderView<Content: View, ResultType: NSFetchRequestResult> : View {
    public let content: (Array<ResultType>) -> Content
    
    private let viewModel: _FetchControllerProviderModel<ResultType>
    
    public init(fetchRequest: NSFetchRequest<ResultType>, managedObjectContext context: NSManagedObjectContext, @ViewBuilder content: @escaping (Array<ResultType>) -> Content) {
        precondition(fetchRequest.sortDescriptors?.count ?? 0 == 0, "Must provide a fetchRequest with at least one sort descriptor")
        
        self.content = content
        self.viewModel = _FetchControllerProviderModel(fetchRequest: fetchRequest, context: context)
    }
    
    public var body: some View {
        return _FetchControllerContainerView(viewModel: self.viewModel) { fetchedResults in
            return self.content(fetchedResults)
        }
    }
}

fileprivate struct _FetchControllerContainerView<Content: View, ResultType: NSFetchRequestResult> : View {
    @ObservedObject private var viewModel: _FetchControllerProviderModel<ResultType>
    
    let content: (Array<ResultType>) -> Content
    
    init(viewModel: _FetchControllerProviderModel<ResultType>, @ViewBuilder content: @escaping (Array<ResultType>) -> Content) {
        self.viewModel = viewModel
        self.content = content
    }
    
    var body: some View {
        return self.content(viewModel.fetchResults)
    }
}

fileprivate class _FetchControllerProviderModel<ResultType: NSFetchRequestResult> : NSObject, NSFetchedResultsControllerDelegate, ObservableObject {
    private let fetchResultsController: NSFetchedResultsController<ResultType>
    
    public var fetchResults: Array<ResultType> {
        return fetchResultsController.fetchedObjects ?? []
    }
    
    init(fetchRequest: NSFetchRequest<ResultType>, context: NSManagedObjectContext) {
        self.fetchResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
        
        super.init()
        
        self.fetchResultsController.delegate = self
        
        try? self.fetchResultsController.performFetch()
    }
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        self.objectWillChange.send()
    }
}

#endif
