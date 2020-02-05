//
//  SBCoreDataDictionaryToDataTransformer.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 20/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation

final class SBCoreDataDictionaryToDataTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        var dataDictionary: NSData?
        
        if value is NSDictionary,
            value != nil {
            guard let valueDictionary = value as? NSDictionary,
                JSONSerialization.isValidJSONObject(valueDictionary) else {
                    DPrint("Could not serialize dictionary to data due to invalid dictionary")
                    return dataDictionary
            }
            
            dataDictionary = try? JSONSerialization.data(withJSONObject: valueDictionary, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData
        }
        
        return dataDictionary
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        var dictionary: NSDictionary?
        
        if let dictData = value as? Data {
            let anyObject = try? JSONSerialization.jsonObject(with: dictData, options: JSONSerialization.ReadingOptions.mutableContainers)
            if anyObject is NSDictionary {
                dictionary = anyObject as? NSDictionary
            }
        }
        
        return dictionary
    }
}
