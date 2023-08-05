//
//  FileManager.swift
//  FBDLKit
//
//  Created by jyck on 2023/8/2.
//

import Foundation


public func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in:.userDomainMask)
    let documentsDirectory = paths[0]
    return documentsDirectory
}
