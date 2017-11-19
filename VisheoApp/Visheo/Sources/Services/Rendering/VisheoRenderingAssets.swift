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
    var photoUrls : [URL] {
        return photoUrlsDict.sorted {$0.0 < $1.0}.map {$0.value}
    }
    
    private var  photoUrlsDict : [Int: URL] = [:]
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
    
    func addPhoto(data: Data, at index: Int) {
        let photoUrl = assetsFolderUrl.appendingPathComponent("photo\(index)")
        photoUrlsDict[index] = photoUrl
        try! data.write(to: photoUrl)
    }
}
