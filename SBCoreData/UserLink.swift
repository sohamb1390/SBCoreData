//
//  UserLink.swift
//  SBCoreDataControllerTests
//
//  Created by Soham Bhattacharjee on 20/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

@objc(UserLink)
public class UserLink: SBCoreDataManagedObject {
    override public class var elementToPropertyMapping: [String: String] {
        // [serverKey: DBKey]
        return ["self": "selfLink", "edit": "editLink", "avatar": "avatarLink"]
    }
    
    override public class var mappedToElement: String? {
        return "_links"
    }
    
    override public class var defaultSortKey: String {
        return "selfLink"
    }
    
    override public class var useAscendingSort: Bool {
        return false
    }
    
    override public class var primaryKeyProperty: String {
        return "primaryKey"
    }
    
    override public class var primaryKeyElement: String {
        return ""
    }
    
    override public func insertRelatedEntities(mappedTo element: JSON, into context: NSManagedObjectContext) {
        // no operation required here
    }
}
