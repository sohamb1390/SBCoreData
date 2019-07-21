//
//  User.swift
//  SBCoreDataControllerTests
//
//  Created by Soham Bhattacharjee on 20/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

@objc(User)
public class User: SBCoreDataManagedObject {
    override public class var elementToPropertyMapping: [String: String] {
        // [serverKey: DBKey]
        return ["id": "userId", "first_name": "firstName", "last_name": "lastName", "gender": "gender", "dob": "dateOfBirth", "email": "email", "phone": "phone", "website": "website", "address": "address", "status": "status"]
    }
    
    override public class var mappedToElement: String? {
        return "result"
    }
    
    override public class var defaultSortKey: String {
        return "firstName"
    }
    
    override public class var useAscendingSort: Bool {
        return true
    }
    
    override public class var primaryKeyProperty: String {
        return "userId"
    }
    
    override public class var primaryKeyElement: String {
        return "id"
    }
    
    override public func insertRelatedEntities(mappedTo element: JSON, into context: NSManagedObjectContext) {
        let relationshipMap = self.entity.relationshipsByName
        for (relationshipName, _) in relationshipMap {
            if relationshipName == "link" {
                self.appendUserLinks(from: element, using: context)
            }
        }
    }
    
    // MARK: - Append User Links
    
    /// Appends links to the user entity
    /// - Parameters:
    ///    - json: Server response JSON dictionary
    ///    - context: An `NSManagedObjectContext` instance which is needed for DB insert query
    private func appendUserLinks(from json: JSON, using context: NSManagedObjectContext) {
        if let linkDict = json["_links"] as? [String: Any], let linkMO = SBCoreDataManagedObjectStore.shared().insertEntity(with: String(describing: UserLink.self), into: context, mappedTo: linkDict, containedIn: json) as? UserLink  {
            linkMO.primaryKey = self.userId
            self.link = linkMO
        }
    }
}
