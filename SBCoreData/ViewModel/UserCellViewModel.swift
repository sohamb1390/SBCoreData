//
//  UserCellViewModel.swift
//  SBCoreData
//
//  Created by Soham Bhattacharjee on 21/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation

struct UserCellViewModel {
    private var user: User
    
    init(with user: User) {
        self.user = user
    }
    
    // MARK: - Helpers
    lazy var userName: String = {
        return "\(user.value(forKey: "firstName") as? String ?? "") \(user.value(forKey: "lastName") as? String ?? "")"
    }()
    
    lazy var dob: String = {
        return user.value(forKey: "dateOfBirth") as? String ?? ""
    }()
    
    lazy var gender: String = {
        return user.value(forKey: "gender") as? String ?? ""
    }()
    
    lazy var address: String = {
        return user.value(forKey: "address") as? String ?? ""
    }()
}
