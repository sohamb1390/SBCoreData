//
//  FileExtension.swift
//  SBCoreDataControllerTests
//
//  Created by Soham Bhattacharjee on 20/07/19.
//  Copyright © 2019 Soham Bhattacharjee. All rights reserved.
//

import Foundation

extension FileManager {
    func documentDirectoryPath() throws -> String? {
        var docDir: String?
        do {
            let documentsURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            docDir = documentsURL.path
        } catch {
            print("could not get docDirPath due to FileManager error: \(error)")
        }
        return docDir
    }
    
    func documentDirectoryURL() throws -> URL {
        var documentDirURL: URL
        
        do {
            documentDirURL = try
                FileManager.default.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
        } catch {
            print("could not get docDirURL due to FileManager error: \(error)")
            throw error
        }
        
        return documentDirURL
    }
    
    func systemCacheDirectoryURL() throws -> URL {
        let cacheDir = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        return cacheDir
    }
}
