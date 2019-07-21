//
//  SBCoreDataArrayToDataTransformer.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 20/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation

final class SBCoreDataArrayToDataTransformer: ValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(_ value: Any?) -> Any? {
        var listAsData: NSData?
        
        if value is NSArray,
            value != nil {
            guard let values = value as? NSArray,
                JSONSerialization.isValidJSONObject(values) else {
                    DPrint("Could not serialize array to data due to invalid array")
                    return listAsData
            }
            
            listAsData = try? JSONSerialization.data(withJSONObject: values, options: JSONSerialization.WritingOptions(rawValue: 0)) as NSData
        }
        
        return listAsData
    }
    
    override func reverseTransformedValue(_ value: Any?) -> Any? {
        var values: NSArray?
        
        if let dataList = value as? Data {
            if let objects = (try? JSONSerialization.jsonObject(with: dataList, options: JSONSerialization.ReadingOptions.mutableContainers)) as? NSArray {
                values = objects
            }
        }
        
        return values
    }
}
