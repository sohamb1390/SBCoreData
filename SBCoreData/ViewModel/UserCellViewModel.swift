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
        return "\(user.firstName ?? "") \(user.lastName ?? "")"
    }()
    
    lazy var dob: String = {
        return user.dateOfBirth ?? ""
    }()
    
    lazy var gender: String = {
        return user.gender ?? ""
    }()
    
    lazy var address: String = {
        return user.gender ?? ""
    }()
}
