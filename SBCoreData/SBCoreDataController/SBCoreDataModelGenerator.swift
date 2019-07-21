//
//  SBCoreDataModelGenerator.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

final class SBCoreDataModelGenerator {
    /// Initialses CoreData stack (a.k.a `SBCoreDataAdapter`) and loads the persistent container into the memory in order to use the DB.
    /// - Parameters:
    ///    - modelFileName: A String containing the core data model file name
    ///    - storeFileName: A String containing the PersistentStore file name
    ///    - model: An instance of `NSManagedObjectModel` which is needed to load the merged model in Unit testing. Apart from that this model parameter is not needed at all.
    ///    - storeType: An type of `SBCoreDataStoreType` which could be either `sql` or `inMemory` for saving objects
    ///    - completionBlock: A closure which gets triggered as soon as the core data stack is initialised and persistent store gets loaded into the memory
    public static func setupCoreDataModel(withModelFileName modelFileName: String,
                                          storeFileName: String,
                                          model: NSManagedObjectModel? = nil,
                                          storeType: SBCoreDataStoreType,
                                          shouldEnableFileProtection: Bool = true,
                                          completionBlock: (() -> Void)? = nil) {
        let dataController = SBCoreDataAdapter.create(from: modelFileName, storeName: storeFileName, model: model, storeType: storeType, shouldEnableFileProtection: shouldEnableFileProtection)
        dataController.load {
            DPrint("Persistent store loaded")
            completionBlock?()
        }
    }
}
