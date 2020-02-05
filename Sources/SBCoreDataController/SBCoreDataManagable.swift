//
//  SBCoreDataManagable.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

public protocol SBCoreDataManagable: SBCoreDataModelable {
    /// Default sorting key which is needed to form an NSSortDescriptor object in order to sort the fetched results. This is a mandatory item that has to be filled in by all the `MO` which conform to the `SBManagedObject` class
    static var defaultSortKey: String { get }
    /// Default Sorting order *(ascending/descending)* which is needed for the NSSortDescriptor object in order to sort the fetched results. This is a mandatory item that has to be filled in by all the `MO` which conform to the `SBManagedObject` class
    static var useAscendingSort: Bool { get }
    /// JSON to Core data property mapper variable. It maps the variable names coming from the server with the ones which are defined in the Core Data entity.
    static var elementToPropertyMapping: [String: String] { get }
    /// Relationship name mapper. It maps the relationship names coming from the server with the ones which are deined in the Core Data entity.
    static var mappedToElement: String? { get }
    /// primary key property/column of an entity used as unique constraint in .xcdatamodel file
    static var primaryKeyProperty: String { get }
    /// corresponding primary key element from API/server response
    static var primaryKeyElement: String { get }
    /// if primary key is made up of 2 properties
    static var hasCompositePrimaryKey: Bool { get }
    /// A Boolean which identifies whether case sensitive search should be enabled for this model object or not
    static var isCaseInsensitiveSearch: Bool { get }
    /// Inserts related entities to Core Data if found in response JSON
    func insertRelatedEntities(mappedTo element: JSON, into context: NSManagedObjectContext)
}
