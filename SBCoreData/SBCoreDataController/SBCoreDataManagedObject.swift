//
//  SBCoreDataManagedObject.swift
//  SBCoreDataController
//
//  Created by Soham Bhattacharjee on 19/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation
import CoreData

open class SBCoreDataManagedObject: NSManagedObject, SBCoreDataManagable {
    open class var defaultSortKey: String {
        fatalError("Subclass should provide proper sort key")
    }
    
    open class var useAscendingSort: Bool {
        fatalError("Subclass should specify sort order")
    }
    
    open class var elementToPropertyMapping: [String: String] {
        fatalError("Subclass should specify mapping between response element to managed object properties")
    }
    
    open class var isCaseInsensitiveSearch: Bool {
        return false
    }
    
    open class var mappedToElement: String? {
        return nil
    }
    
    open class var primaryKeyProperty: String {
        return ""
    }
    
    open class var primaryKeyElement: String {
        return ""
    }
    
    open class var hasCompositePrimaryKey: Bool {
        return false
    }
    
    open func insertRelatedEntities(mappedTo element: JSON, into context: NSManagedObjectContext) {
        // no operation required here
    }
    
    override open func setValue(_ value: Any?, forUndefinedKey key: String) {
        // no operation required here
        DPrint("no key=\(key) found in the managed objecct")
    }
    
    override open func value(forUndefinedKey key: String) -> Any? {
        return nil
    }
    
    /// Sets object values for keys from the element mapping dictionary which are coming from the server
    /// - Parameters:
    ///    - keyedValues: Server Response JSON dictionary
    ///    - mapping: Element Mapping Dictionary
    ///    - dateFormatter: Desired date formatter for saving dates
    func setValuesForKeys(_ keyedValues: JSON, from mapping: [String: String], _ dateFormatter: DateFormatter? = nil) {
        var filteredKeyedValues = JSON(minimumCapacity: mapping.count)
        let attributes = self.entity.attributesByName
        
        for (elementName, propertyName) in mapping {
            if let propVal = keyedValues[elementName] {
                if let actualVal = actualTypeValue(for: propertyName, with: propVal, from: attributes) {
                    filteredKeyedValues[propertyName] = actualVal
                }
            }
        }
        
        if !filteredKeyedValues.isEmpty {
            self.setValuesForKeys(filteredKeyedValues)
        }
    }
    
    /// Returns actual value type of individual property
    /// - Parameters:
    ///     - propertyName: The key name inside the dictionary for which the type would be returned
    ///     - value: Value of the property
    ///     - attributes: The dictionary containing all the key value pairs (JSON) coming from the server
    ///     - dateFormatter: Desired date formatter for saving dates
    /// - Returns: Value of the property.
    private func actualTypeValue(for propertyName: String,
                                 with value: Any,
                                 from attributes: [String: NSAttributeDescription],
                                 _ dateFormatter: ISO8601DateFormatter? = nil) -> Any? {
        let attributeType = attributes[propertyName]?.attributeType
        var actualValue = value
        
        if attributeType == .stringAttributeType,
            let number = value as? NSNumber {
            actualValue = number.stringValue
        } else if ((attributeType == .integer16AttributeType) || (attributeType == .integer32AttributeType) || (attributeType == .integer64AttributeType) || (attributeType == .booleanAttributeType)),
            let string = value as? String,
            let intVal = Int(string) {
            actualValue = intVal
        } else if attributeType == .floatAttributeType,
            let string = value as? String,
            let dblVal = Double(string) {
            actualValue = dblVal
        } else if attributeType == .dateAttributeType,
            var string = value as? String {
            var valueDateFormatter: ISO8601DateFormatter
            
            if let df: ISO8601DateFormatter = dateFormatter {
                valueDateFormatter = df
            } else {
                valueDateFormatter = ISO8601DateFormatter()
                if #available(iOS 11.2, *) {
                    valueDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                } else {
                    string = string.replacingOccurrences(of: "\\.\\d+", with: "", options: .regularExpression)
                }
            }
            
            if let date = valueDateFormatter.date(from: string) as Date? {
                actualValue = date
            }
        } else if attributeType == .transformableAttributeType {
            var dictionary: JSON?
            
            if let string = value as? String,
                let strData = string.data(using: .utf8),
                let anyObject = ((try? JSONSerialization.jsonObject(with: strData, options: JSONSerialization.ReadingOptions.mutableContainers)) as? JSON) {
                dictionary = anyObject
            } else if value is JSON {
                dictionary = value as? JSON
            }
            
            if let dictionary = dictionary {
                actualValue = dictionary
            }
        }
        
        return actualValue
    }
    
    /// Converts model object into JSON object based on mapping dictionary
    /// - Parameters:
    ///    - mapping: A mapping dictionary which is needed to get the values from the model and then construct a JSON object
    /// - Returns: A JSON object
    public func toResponseElementDictionary(_ mapping: [String: String]) -> JSON {
        var elementDictionary = JSON(minimumCapacity: mapping.count)
        
        for (elementName, propertyName) in mapping {
            if let elementValue = value(forKey: propertyName) {
                elementDictionary[elementName] = elementValue
            }
        }
        
        return elementDictionary
    }
    
    /// A convenient method for saving the ManagedObject which actually internally does the context saving
    public func save() {
        if let moc = self.managedObjectContext {
            SBCoreDataAdapter.shared().save(context: moc)
        }
    }
}
