//
//  SBCoreDataModelable.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation

public protocol SBCoreDataModelable {
    /// Creates Codable Model after decoding from raw data which will come from the server
    /// - Parameters:
    ///    - json: Response Dictionary coming from the server
    ///    - type: Custom Model object which also conforms to Codable protocol treated as generic
    /// - Returns: Custom Model object
    static func createCodableModel<T: Codable>(from json: JSON, of type: T.Type) -> T?
}

public extension SBCoreDataModelable {
    static func createCodableModel<T: Codable>(from json: JSON, of type: T.Type) -> T? {
        var model: T?
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json, options: JSONSerialization.WritingOptions.prettyPrinted)
            model = try JSONDecoder().decode(type, from: jsonData)
        } catch {
            DPrint("Could not decode object of type: \(T.self), due to an error=\(error)")
        }
        
        return model
    }
}
