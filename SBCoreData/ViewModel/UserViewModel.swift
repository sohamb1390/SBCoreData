//
//  UserViewModel.swift
//  SBCoreData
//
//  Created by Soham Bhattacharjee on 21/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData
import CoreGraphics

@objc
class UserViewModel: NSObject {
    // MARK: Variables
    @objc dynamic private var dataSource: [User] = []
    
    var onDataSourceLoaded: (() -> Void)?
    
    private var cellDataSource: [UserCellViewModel] = []
    
    private var dataSourceObservation: NSKeyValueObservation?
    
    fileprivate lazy var fetchedResultsController: NSFetchedResultsController<User> = {
        // Create Fetch Request
        let fetchRequest: NSFetchRequest<User> = User.fetchRequest() as! NSFetchRequest<User>
        
        // Configure Fetch Request
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: User.defaultSortKey, ascending: User.useAscendingSort)]
        
        // Create Fetched Results Controller
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: SBCoreDataAdapter.shared().viewContext, sectionNameKeyPath: nil, cacheName: nil)
        
        // Configure Fetched Results Controller
        fetchedResultsController.delegate = self
        
        return fetchedResultsController
    }()
    
    // MARK: - Constructor
    override init() {
        super.init()
        self.dataSourceObservation = self.observe(\UserViewModel.dataSource, options: .new) { [weak self] (person, change) in
            var vms: [UserCellViewModel] = []
            for user in change.newValue ?? [] {
                let cVM = UserCellViewModel(with: user)
                vms.append(cVM)
            }
            self?.cellDataSource = vms
            self?.onDataSourceLoaded?()
        }
    }
    
    deinit {
        self.dataSourceObservation?.invalidate()
    }
    
    // MARK: - DataSource
    
    /// Loads user set from the json file and saves it to the core data. Also it notifies internal observer to initialise the cell viewModels in order to update the UITableView
    func loadDataSource() {
        if let path = Bundle(for: type(of: self)).path(forResource: "SBCoreDataControlerTestResponse", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? JSON {
                    // do stuff
                    SBCoreDataManagedObjectStore.shared().createOrUpdateEntities(of: NSStringFromClass(User.self), from: jsonResult)
                    try? self.fetchedResultsController.performFetch()
                    self.dataSource = self.fetchedResultsController.fetchedObjects ?? []
                }
            } catch {
                // handle error
                DPrint(error.localizedDescription)
            }
        }
    }
    
    /// Loads updated user set from the json file and updates it to the core data. Also it notifies internal observer to initialise the cell viewModels in order to update the UITableView
    func updateDataSource() {
        if let path = Bundle(for: type(of: self)).path(forResource: "SBCoreDataControllerUpdateResponse", ofType: "json") {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
                let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
                if let jsonResult = jsonResult as? JSON {
                    // do stuff
                    SBCoreDataManagedObjectStore.shared().createOrUpdateEntities(of: NSStringFromClass(User.self), from: jsonResult)
                    try? self.fetchedResultsController.performFetch()
                    self.dataSource = self.fetchedResultsController.fetchedObjects ?? []
                }
            } catch {
                // handle error
                DPrint(error.localizedDescription)
            }
        }
    }
    
    /// Returns the number of rows for a particular section
    /// - Parameters:
    ///    - section: A particular section for which total number of rows would get returned
    func numberOfRowsForSection(_ section: Int) -> Int {
        return cellDataSource.count
    }
    
    /// Returns corresponding cell view model for a particular indexPath
    /// - Parameters:
    ///    - indexPath: A particular indexPath for which a cell view model would get returned
    func cellViewModel(at indexPath: IndexPath) -> UserCellViewModel {
        let cvm = cellDataSource[indexPath.row]
        return cvm
    }
    
    /// Returns the height of the header
    /// - Parameters:
    ///    - section: A Particular section for which header height would be returned
    func heightForHeaderInSection(_ section: Int) -> CGFloat {
        return 44.0
    }
    
    /// Returns the header title
    /// - Parameters:
    ///    - section: A Particular section for which header title string would be returned
    func titleOfTheHeader(in section: Int) -> String {
        let count = self.getResultCount()
        return "Total Users: \(count)"
    }
    
    /// Returns corresponding url for a particular indexPath
    /// - Parameters:
    ///    - indexPath: A particular indexPath for which a user link would get returned
    func getURL(for indexPath: IndexPath) -> URL? {
        let user = dataSource[indexPath.row]
        
        if let userLink = user.value(forKey: "link") as? UserLink,
            let selfLink = userLink.value(forKey: "selfLink") as? [String: Any],
            let href = selfLink["href"] as? String, let url = URL(string: href) {
            return url
        }
        return nil
    }
    
    /// Returns the total number of result
    func getResultCount() -> Int {
        return self.dataSource.count
    }
}

// MARK: - NSFetchedResultsControllerDelegate
extension UserViewModel: NSFetchedResultsControllerDelegate {
}
