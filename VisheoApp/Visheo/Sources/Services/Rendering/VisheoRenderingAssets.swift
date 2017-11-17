//
//  VisheoRenderingAssets.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

class VisheoRenderingAssets {
    private(set) var coverUrl : URL?
    let assetsFolderUrl : URL
    
    init() {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderUUID = UUID().uuidString
        assetsFolderUrl = documentsUrl.appendingPathComponent(folderUUID)
        try! FileManager.default.createDirectory(at: assetsFolderUrl, withIntermediateDirectories: false, attributes: nil)
    }
    
    func setCover(with data: Data) {
        coverUrl = assetsFolderUrl.appendingPathComponent("cover")
        try! data.write(to: coverUrl!)        
    }
}
