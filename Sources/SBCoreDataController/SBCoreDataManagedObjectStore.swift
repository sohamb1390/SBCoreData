//
//  SBCoreDataManagedObjectStore.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

public final  class SBCoreDataManagedObjectStore {
    // MARK: Variables
    
    /// A type alias for the instance type `SBCoreDataManagedObject` for convenience
    public typealias Entity = SBCoreDataManagedObject
    
    /// Singleton's shared instance
    private static var sharedStore: SBCoreDataManagedObjectStore!
    
    // MARK: - Constructors
    
    /// Singleton constructor of `SBCoreDataManagedObjectStore`
    public static func shared() -> SBCoreDataManagedObjectStore {
        if sharedStore == nil {
            sharedStore = SBCoreDataManagedObjectStore()
        }
        
        return sharedStore
    }
    
    /// Private constructor
    private init() { }
    
    // MARK: - Create/Update objects
    
    /// Method used to create single or multiple core data objects from provided type & json params. It uses background context for inserting/updating entites.
    /// - Parameters:
    ///    - type: String representing entityNames that needs to be created in the core data
    ///    - json: Dictionary containing required element and values. This dictionary is used to set property values of created entity.
    /// - Returns: A list of newly created/updated managed objects
    @discardableResult
    public func createOrUpdateEntities(of type: String, from json: JSON?) -> [Entity]? {
        guard let json = json else { return nil }
        
        let entityName = type
        var elementName: String?
        var entities = [Entity]()
        
        if let entityClass = NSClassFromString(entityName) as? SBCoreDataManagable.Type {
            elementName = entityClass.mappedToElement
        }
        
        guard let mappedElementName = elementName else {
            if let entity: Entity = insertOrUpdateEntity(with: entityName, mappedTo: json, containedIn: json) {
                entities.append(entity)
            }
            
            return entities
        }
        
        guard json.keys.contains(mappedElementName), let anyObject = json[mappedElementName] else {
            return entities
        }
        
        if let elementValue = anyObject as? JSON,
            let entity: Entity = insertOrUpdateEntity(with: entityName, mappedTo: elementValue, containedIn: json) {
            entities.append(entity)
        } else if let mappedElementValues = anyObject as? [JSON], !mappedElementValues.isEmpty {
            let bgContext = SBCoreDataAdapter.shared().backgroundContext()
            bgContext.performAndWait {
                for mappedElementValue in mappedElementValues {
                    if let updatedEntity: Entity = findAndUpdateEntity(with: entityName, mappedTo: mappedElementValue, context: bgContext) {
                        entities.append(updatedEntity)
                        updatedEntity.insertRelatedEntities(mappedTo: mappedElementValue, into: bgContext)
                    } else if let entity: Entity = insertEntity(with: entityName, into: bgContext, mappedTo: mappedElementValue, containedIn: json) {
                        entities.append(entity)
                    }
                }
                
                if !entities.isEmpty {
                    SBCoreDataAdapter.shared().save(context: bgContext)
                }
            }
        } else {
            DPrint("WARNING: anyObject type is \(anyObject) is not handled for core data entity creation")
        }
        
        return entities
    }
    
    /// Finds and update values of a particular managed object for an entity. Make sure when you declare any `SBCoreDataManagedObject` sub class, it should have atleast one primary key, optionally you can have a composite key as well.
    /// - Parameters:
    ///    - name: String representing entityName that needs to be updated in the core data
    ///    - element: New set of key-value pairs which would update the existing value
    ///    - context: An `NSManagedObjectContext`
    private func findAndUpdateEntity<Entity: SBCoreDataManagedObject>(with name: String, mappedTo element: JSON, context: NSManagedObjectContext) -> Entity? {
        var updatedEntity: Entity?
        
        if let entityClass = NSClassFromString(name) as? SBCoreDataManagedObject.Type,
            !entityClass.primaryKeyProperty.isEmpty,
            !entityClass.primaryKeyElement.isEmpty,
            !entityClass.defaultSortKey.isEmpty {
            var keyFilter: NSPredicate?
            if entityClass.hasCompositePrimaryKey {
                let pkProps = entityClass.primaryKeyProperty.split(separator: ",")
                let pkElementNames = entityClass.primaryKeyElement.split(separator: ",")
                var filters = [NSPredicate]()
                for index in 0..<pkProps.count {
                    let pkProp = String(pkProps[index])
                    let pkElement = String(pkElementNames[index])
                    
                    if let pkElementValue = element[pkElement] as? String {
                        let filter = NSPredicate(format: " (%K == %@) ", pkProp, pkElementValue)
                        filters.append(filter)
                    }
                }
                
                if filters.count > 1 {
                    keyFilter = NSCompoundPredicate(andPredicateWithSubpredicates: filters)
                } else {
                    keyFilter = filters.first
                }
            } else if let pkElementValue = element[entityClass.primaryKeyElement] as? String {
                keyFilter = NSPredicate(format: " (%K == %@) ", entityClass.primaryKeyProperty, pkElementValue)
            }
            
            guard let pKeyFilter = keyFilter else {
                return updatedEntity
            }
            
            let sortDesc = NSSortDescriptor(key: entityClass.defaultSortKey, ascending: true)
            // let fetchRequest = NSFetchRequest<SBCoreDataManagedObject>(entityName: NSStringFromClass(entityClass))
            let fetchRequest = entityClass.fetchRequest()
            let entities = SBCoreDataAdapter.shared().query(entityClass, search: pKeyFilter, sort: [sortDesc], context: context, request: fetchRequest)
            
            if !entities.isEmpty, let entity = entities.first as? Entity {
                updatedEntity = entity
                updatedEntity?.setValuesForKeys(element, from: entityClass.elementToPropertyMapping)
            }
        }
        
        return updatedEntity
    }
    
    /// This method either inserts the new managed objects or updates the existing objects in the core data
    /// - Parameters:
    ///    - name: String representing entityName that needs to be updated in the core data
    ///    - element: Mapping Dictionary coming from the server response
    public func insertOrUpdateEntity<Entity: SBCoreDataManagedObject>(with name: String, mappedTo element: JSON, containedIn responseJSON: JSON) -> Entity? {
        let bgContext = SBCoreDataAdapter.shared().backgroundContext()
        var newEntity: Entity?
        
        if let existingEntity: Entity = findAndUpdateEntity(with: name, mappedTo: element, context: bgContext) {
            existingEntity.insertRelatedEntities(mappedTo: element, into: bgContext)
            newEntity = existingEntity
        } else {
            newEntity = insertEntity(with: name, into: bgContext, mappedTo: element, containedIn: responseJSON)
        }
        
        SBCoreDataAdapter.shared().save(context: bgContext)
        return newEntity
    }
    
    public func insertEntity<Entity: SBCoreDataManagedObject>(with name: String, into bgContext: NSManagedObjectContext, mappedTo element: JSON, containedIn responseJSON: JSON) -> Entity? {
        return insertOrUpdateEntity(with: name, into: bgContext, mappedTo: element, containedIn: responseJSON, forceCreate: true)
    }
    
    private func insertOrUpdateEntity<Entity: SBCoreDataManagedObject>(with name: String, into bgContext: NSManagedObjectContext, mappedTo element: JSON, containedIn responseJSON: JSON, forceCreate: Bool) -> Entity? {
        var newEntity: Entity?
        
        bgContext.performAndWait {
            if !forceCreate, let existingEntity: Entity = findAndUpdateEntity(with: name, mappedTo: element, context: bgContext) {
                existingEntity.insertRelatedEntities(mappedTo: element, into: bgContext)
                newEntity = existingEntity
            }
            
            if newEntity == nil, let createdEntity = NSEntityDescription.insertNewObject(forEntityName: name, into: bgContext) as? Entity,
                let entityClass = NSClassFromString(name) as? SBCoreDataManagable.Type {
                createdEntity.setValuesForKeys(element, from: entityClass.elementToPropertyMapping)
                createdEntity.insertRelatedEntities(mappedTo: element, into: bgContext)
                newEntity = createdEntity
            }
        }
        
        return newEntity
    }
}
