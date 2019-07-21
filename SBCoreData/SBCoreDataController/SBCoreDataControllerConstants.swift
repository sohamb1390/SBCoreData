//
//  SBCoreDataControllerConstants.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

/// A Dictionary which contains key as `String` and value as `any` type which would represent the API response
public typealias JSON = [String: Any]

/// Debug Mode for print
func DPrint(_ items: Any...) {
    
    #if DEBUG
    var startIdx = items.startIndex
    let endIdx = items.endIndex
    
    repeat {
        Swift.print(items[startIdx])
        startIdx += 1
    }
    while startIdx < endIdx
    
    #endif
}

/// Core Data Store type enum
public enum SBCoreDataStoreType: String {
    case sql = "NSSQLiteStoreType"
    case inMemory = "NSInMemoryStoreType"
}
