//
//  SBCoreDataAdapter.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

public final class SBCoreDataAdapter {
    // MARK: Variables
    
    /// Instance of PersistantContainer
    let persistentContainer: NSPersistentContainer
    
    /// DB Store Name
    let storeName: String
    
    /// Store Type
    let storeType: SBCoreDataStoreType
    
    /// File protection checker
    let shouldEnableFileProtection: Bool
    
    /// Child ManagedObjectContext with private queue concurrency type
    public lazy var privateContext: NSManagedObjectContext = {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .privateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentContainer.persistentStoreCoordinator
        return managedObjectContext
    }()
    
    /// Singleton's shared instance
    private static var sharedController: SBCoreDataAdapter!
    
    /// Main queue/thread context
    lazy public var viewContext: NSManagedObjectContext = {
        guard Thread.isMainThread else {
            fatalError("viewContext is called from background thread: \(Thread.current)")
        }
        return self.persistentContainer.viewContext
    }()
    
    // MARK: - Constructors
    
    /// Singleton constructor  of `SBCoreDataAdapter`
    public static func shared() -> SBCoreDataAdapter {
        if sharedController == nil {
            fatalError("Core data stack is not initialized")
        }
        return sharedController
    }

    /// Private constructor
    /// - Parameters:
    ///    - modelName: Name of the model file
    ///    - storeName: Name of the Persistent Store
    ///    - model: An instance of `NSManagedObjectModel` which is needed to load the merged model in Unit testing. Apart from that this model parameter is not needed at all.
    ///    - storeType: An type of `SBCoreDataStoreType` which could be either `sql` or `inMemory` for saving objects
    ///    - shouldEnableFileProtection: A Boolean which identifies whether file protection should be enabled or not
    private init(modelName: String, storeName: String, model: NSManagedObjectModel? = nil, storeType: SBCoreDataStoreType, shouldEnableFileProtection: Bool = true) {
        if let model = model {
            self.persistentContainer = NSPersistentContainer(name: modelName, managedObjectModel: model)
        } else {
            self.persistentContainer = NSPersistentContainer(name: modelName)
        }
        self.storeName = storeName
        self.storeType = storeType
        self.shouldEnableFileProtection = shouldEnableFileProtection
        
        // PersistentContainer Configuration
        configure(storeName)
    }
    
    /// Public constructor interface
    /// - Parameters:
    ///    - modelName: Name of the model file
    ///    - storeName: Name of the Persistent Store
    ///    - model: An instance of `NSManagedObjectModel` which is needed to load the merged model in Unit testing. Apart from that this model parameter is not needed at all.
    ///    - storeType: An type of `SBCoreDataStoreType` which could be either `sql` or `inMemory` for saving objects
    ///    - shouldEnableFileProtection: A Boolean which identifies whether file protection should be enabled or not
    static func create(from modelFileName: String, storeName: String, model: NSManagedObjectModel? = nil, storeType: SBCoreDataStoreType, shouldEnableFileProtection: Bool = true) -> SBCoreDataAdapter {
        ValueTransformer.setValueTransformer(SBCoreDataDictionaryToDataTransformer(), forName: NSValueTransformerName(rawValue: "DictionaryToDataTransformer"))
        ValueTransformer.setValueTransformer(SBCoreDataArrayToDataTransformer(), forName: NSValueTransformerName(rawValue: "ArrayToDataTransformer"))
        
        let controller = SBCoreDataAdapter(modelName: modelFileName, storeName: storeName, model: model, storeType: storeType, shouldEnableFileProtection: shouldEnableFileProtection)
        SBCoreDataAdapter.sharedController = controller
        return controller
    }
    
    // MARK: - Configuration
    /// Configures `NSPersistentContainer`
    /// - Parameters:
    ///    - storeName: Name of the Persistent Store
    private func configure(_ storeName: String) {
        let storeURL = NSPersistentContainer.defaultDirectoryURL().appendingPathComponent("\(storeName).sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        description.shouldInferMappingModelAutomatically = true
        description.shouldMigrateStoreAutomatically = true
        switch self.storeType {
        case .sql:
            description.type = NSSQLiteStoreType
        default:
            description.type = NSInMemoryStoreType
        }
        
        if self.shouldEnableFileProtection {
            if let completionProtection = FileProtectionType.complete as NSObject? {
                description.setOption(completionProtection, forKey: NSPersistentStoreFileProtectionKey)
            }
        }
        
        self.persistentContainer.persistentStoreDescriptions = [description]
    }
    
    /// Configures Main/View ManagedObjectContext
    private func configureViewContext() {
        self.viewContext.automaticallyMergesChangesFromParent = true
        self.viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump
    }
    
    // MARK: - Loading Persistent Container
    /// Loads persistent container into the memory and when it gets loaded, it also configures the main ManagedObjectContext
    /// - Parameters:
    ///    - completion: A closure which gets triggered as soon as the container is loaded into the memory
    func load(completion: (() -> Void)? = nil) {
        self.persistentContainer.loadPersistentStores { [weak self] (storeDescription, error) -> Void in
            DPrint("store options =\(storeDescription.options)")
            guard error == nil else {
                fatalError(error?.localizedDescription ?? "")
            }
            
            self?.configureViewContext()
            completion?()
        }
    }
    
    // MARK: - Background/Child context handlers
    /// Initialises a new background context
    public func backgroundContext() -> NSManagedObjectContext {
        let newBackgroundContext = self.persistentContainer.newBackgroundContext()
        newBackgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump
        return newBackgroundContext
    }
    
    /// Provides a closure to handle long running tasks in persistant container's closure.
    /// - Parameters:
    ///    - handler: A closure which returns with a block where we can execute long running DB tasks. It also provides the background context for running it.
    public func backgroundHanlder(_ handler: @escaping ((_ context: NSManagedObjectContext) -> Void)) {
        self.persistentContainer.performBackgroundTask { (moContext) in
            handler(moContext)
        }
    }
    
    // MARK: - Core Data Handlers
    
    // MARK: Save
    /// Saves the unsaved model changes into Persistent Store. This holds the current thread while saving the changes.
    /// - Parameters:
    ///    - context: A ManagedObjectContext instance which is needed to save the changes.
    public func save(context: NSManagedObjectContext) {
        context.performAndWait {
            if context.hasChanges {
                do {
                    try context.save()
                } catch {
                    DPrint("could not save due to error: \(error)")
                }
            }
        }
    }
    
    // MARK: Fetch
    
    /// Fetches database objects using filters/sort attributes.
    /// This method defines a generic type which is kind of any `NSManagedObject` class
    /// so that we can consume this method for any ManagedObject
    /// - Parameters:
    ///   - type: Generic type which could be any kind of `NSManagedObject` class type
    ///   - search: NSPredicate instance which could be used to filter out the fetched results
    ///   - sort: An array of `NSSortDescriptor` which could be used to sort the fetched results
    /// - Returns: Any type of `NSManagedObject` instance
    public func query<T>(_ type: T.Type,
                  search: NSPredicate? = nil,
                  sort: [NSSortDescriptor]? = nil,
                  wantFault: Bool? = true,
                  fetchLimit: Int = 0,
                  context: NSManagedObjectContext? = nil) -> [T] where T: NSManagedObject {
        let request = T.fetchRequest()
        return query(type, search: search, sort: sort, wantFault: wantFault, fetchLimit: fetchLimit, context: context, request: request)
    }
    
    /// Fetches database objects synchronously using filters/sort attributes.
    /// This method defines a generic type which is kind of any NSManagedObject class
    /// so that we can consume this method for any ManagedObject
    /// - Parameters:
    ///   - type: Generic type which could be any kind of `NSManagedObject` class type
    ///   - search: NSPredicate instance which could be used to filter out the fetched results
    ///   - sort: An array of `NSSortDescriptor` which could be used to sort the fetched results
    ///   - wantFault: A Boolean which identifies whether the returning result should be faulted or not
    ///   - fetchLimit: An integer which defines the limit of the result should get returned from the fetch query
    ///   - request: An instance of `NSFetchRequest` which is needed to perform fetch query
    ///   - context: An optional instance of `NSManagedObjectContext` which is needed to perform the fetch query
    /// - Returns: Any type of `NSManagedObject` instance
    public func query<T>(_ type: T.Type,
                  search: NSPredicate? = nil,
                  sort: [NSSortDescriptor]? = nil,
                  wantFault: Bool? = true,
                  fetchLimit: Int = 0,
                  context: NSManagedObjectContext? = nil,
                  request: NSFetchRequest<NSFetchRequestResult>) -> [T] where T: NSManagedObject {
        // Set predicates
        if let predicate = search {
            request.predicate = predicate
        }
        
        // Set sorting mechanism
        if let sortDescriptor = sort {
            request.sortDescriptors = sortDescriptor
        }
        
        // Whether the objects should be faulted or not explicitly
        if wantFault == false {
            request.returnsObjectsAsFaults = false
        }
        
        // Predined fetch limit
        if fetchLimit > 0 {
            request.fetchLimit = fetchLimit
        }
        
        // Execute fetch query
        var results: [Any] = []
        do {
            if let context = context {
                context.performAndWait {
                    results = try context.fetch(request)
                }
            } else {
                viewContext.performAndWait { [weak self] in
                    results = try self?.viewContext.fetch(request) ?? []
                }
            }
            return results as? [T] ?? []
        } catch {
            DPrint("Error with request: \(error)")
            return []
        }
    }
    
    /// A Public method which fetches database objects asynchronously using filters/sort attributes.
    /// This method defines a generic type which is kind of any NSManagedObject class
    /// so that we can consume this method for any ManagedObject
    /// - Parameters:
    ///   - type: Generic type which could be any kind of `NSManagedObject` class type
    ///   - search: NSPredicate instance which could be used to filter out the fetched results
    ///   - sort: An array of `NSSortDescriptor` which could be used to sort the fetched results
    ///   - context: An optional instance of `NSManagedObjectContext` which is needed to perform the fetch query
    ///   - wantFault: A Boolean which identifies whether the returning result should be faulted or not
    ///   - fetchLimit: An integer which defines the limit of the result should get returned from the fetch query
    ///   - request: An instance of `NSFetchRequest` which is needed to perform fetch query
    ///   - completionHandler: A closure which returns the list of fetched model objects
    public func asynchronousFetchQuery<T>(_ type: T.Type,
                                   search: NSPredicate? = nil,
                                   sort: [NSSortDescriptor]? = nil,
                                   context: NSManagedObjectContext? = nil,
                                   wantFault: Bool? = true,
                                   fetchLimit: Int = 0,
                                   completionHandler: @escaping (([T]) -> Void)) where T: NSManagedObject {
        
        let request = T.fetchRequest()
        
        // Set predicates
        if let predicate = search {
            request.predicate = predicate
        }
        
        // Set sorting mechanism
        if let sortDescriptor = sort {
            request.sortDescriptors = sortDescriptor
        }
        
        // Whether the objects should be faulted or not explicitly
        if wantFault == false {
            request.returnsObjectsAsFaults = false
        }
        
        // Predined fetch limit
        if fetchLimit > 0 {
            request.fetchLimit = fetchLimit
        }
        
        // Initialize Asynchronous Request
        let asynchronousFetchRequest = NSAsynchronousFetchRequest(fetchRequest: request) { (asyncFetchResult) -> Void in
            if let result = asyncFetchResult.finalResult {
                // Update Items
                completionHandler(result as? [T] ?? [])
            }
        }
        
        do {
            _ = (context == nil) ? try self.viewContext.execute(asynchronousFetchRequest) : try context?.execute(asynchronousFetchRequest)
        } catch {
            DPrint("error")
        }
    }
    
    /// Fetches `MO` object from object ManagedObject URL. This method should be invoked when we saved ManagedObjectId URL in UserDefaults and again we are fetching the exact ManagedObject from the saved URLs.
    ///
    /// - Parameters:
    ///   - type: Generic type which could be any kind of NSManagedObject class type
    ///   - url: Object URL
    ///   - context: `ManagedObjectContext` instance which is needed to fetch the `MO` objects from the DB
    /// - Returns: An instance of `MO`
    public func fetchRecordsFromManagedObjectObjectURL<T>(withType type: T.Type,
                                                          url: URL,
                                                          context: NSManagedObjectContext? = nil) -> T? where T: NSManagedObject {
        if let objectId = (context ?? viewContext).persistentStoreCoordinator?.managedObjectID(forURIRepresentation: url) {
            let object = (context ?? viewContext).object(with: objectId) as? T
            return object
        }
        
        return nil
    }
    
    /// Returns the total count of the ManagedObjects for a particular entity
    /// - Parameters:
    ///    - entityName: Name of the entity
    ///    - filter: `NSPredicate` instance which could be used to filter out the fetched results
    ///    - context: An instance of `NSManagedObjectContext` which is needed to perform the fetch query
    func countForEntity(withName entityName: String,
                        filter: NSPredicate? = nil,
                        context: NSManagedObjectContext) -> Int {
        let request = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        request.predicate = filter
        let entityCount = try? context.count(for: request)
        return entityCount ?? 0
    }
    
    // MARK: Insert
    
    /// Creates a ManagedObject into the DB
    /// - Parameters:
    ///    - type: Type of the NSManagedObject
    ///    - context: An instance of `NSManagedObjectContext` which is needed to create a managed object
    /// - Returns: Newly created `NSManagedObject`
    public func addRecord<T>(_ type: T.Type, context: NSManagedObjectContext? = nil) -> T? where T: NSManagedObject {
        let entityName = T.description()
        if let entity = NSEntityDescription.entity(forEntityName: entityName, in: context ?? self.viewContext) {
            let record = T(entity: entity, insertInto: context)
            return record
        }
        return nil
    }
    
    // MARK: Remove
    
    /// Removes records from Core Data
    ///
    /// - Parameters:
    ///   - type: Generic type which could be any kind of NSManagedObject class type
    ///   - search: `NSPredicate` instance which could be used to filter out the fetched results
    ///   - context: An optional instance of `NSManagedObjectContext` which is needed to perform the delete query
    ///   - shouldSave: A Boolean which identifies whether the context needs to be saved after deleting or not. This is an optional parameter with true value, you can pass with any boolean value as an argument explicitly
    public func deleteRecords<T>(_ type: T.Type,
                          search: NSPredicate? = nil,
                          context: NSManagedObjectContext,
                          shouldSave: Bool = true)  where T: NSManagedObject {
        let results = query(T.self, search: search, sort: nil, context: context)
        
        if !results.isEmpty {
            for record in results {
                context.delete(record)
            }
            
            if shouldSave {
                self.save(context: context)
            }
        }
    }
    
    /// Removes records from Core Data using batch delete mechanism
    ///
    /// - Parameters:
    ///   - entityType: Entity name
    ///   - context: An optional instance of `NSManagedObjectContext` which is needed to perform the delete query
    ///   - predicate: NSPredicate instance which could be used to filter out the fetched results
    ///   - shouldSave: A Boolean which identifies whether the context needs to be saved after deleting or not. This is an optional parameter with true value, you can pass with any boolean value as an argument explicitly
    public func deleteBatchEntities(entityType: String,
                                    context: NSManagedObjectContext,
                                    predicate: NSPredicate? = nil,
                                    shouldSave: Bool = true) {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entityType)
        fetchRequest.predicate = predicate
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        context.performAndWait {
            do {
                try context.execute(deleteRequest)
                if shouldSave {
                    try context.save()
                }
            } catch {
                DPrint (error)
            }
        }
    }
    
    /// Removes Core Data PersistentStore
    public func removeStore() {
        do {
            let storeDirURL = NSPersistentContainer.defaultDirectoryURL()
            let storeURL = storeDirURL.appendingPathComponent("\(storeName).sqlite")
            try persistentContainer.persistentStoreCoordinator.destroyPersistentStore(at: storeURL, ofType: NSSQLiteStoreType)
            try FileManager.default.removeItem(at: storeDirURL)
        } catch {
            DPrint("Could not remove store due to an error=\(error)")
        }
    }
}
