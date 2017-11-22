//
//  VisheoRenderingAssets.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

class VisheoRenderingAssets {
    let originalOccasion: OccasionRecord
    let assetsFolderUrl : URL
    
    init(originalOccasion: OccasionRecord) {
        self.originalOccasion = originalOccasion
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let folderUUID = UUID().uuidString
        assetsFolderUrl = documentsUrl.appendingPathComponent(folderUUID)
        try! FileManager.default.createDirectory(at: assetsFolderUrl, withIntermediateDirectories: false, attributes: nil)
    }
    
    // MARK: Cover
    private(set) var coverUrl : URL?
    private(set) var coverIndex: Int?
    
    func setCover(with data: Data, at index: Int) {
        coverIndex = index
        coverUrl = assetsFolderUrl.appendingPathComponent("cover")
        try! data.write(to: coverUrl!)
    }
    
    // MARK: Photos
    
    private var  photoUrlsDict : [Int: URL] = [:]
    
    var photosLocalIds : [String] = []
    
    var photoUrls : [URL] {
        return photoUrlsDict.sorted {$0.0 < $1.0}.map {$0.value}
    }
    
    func removePhotos() {
        photoUrlsDict.forEach { (number, photoUrl) in
            try? FileManager.default.removeItem(at: photoUrl)
        }
        photosLocalIds.removeAll()
        photoUrlsDict.removeAll()
    }
    
    func addPhoto(data: Data, at index: Int) {
        let photoUrl = assetsFolderUrl.appendingPathComponent("photo\(index)")
        photoUrlsDict[index] = photoUrl
        try! data.write(to: photoUrl)
    }
    
    // MARK: Video
    
    var videoUrl : URL {
        return assetsFolderUrl.appendingPathComponent("video.mov")
    }
    
    var trimmedVideoUrl : URL {
        return assetsFolderUrl.appendingPathComponent("final_video.mov")
    }
    
    func removeVideo() {
        try? FileManager.default.removeItem(at: videoUrl)
    }
}
