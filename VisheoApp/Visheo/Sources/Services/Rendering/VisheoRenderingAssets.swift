//
//  VisheoRenderingAssets.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import AVFoundation


class VisheoRenderingAssets {
    let originalOccasion: OccasionRecord
    let assetsFolderUrl : URL
    var assetsFolderRelUrl : URL {
        return URL(string: id)!
    }
    private var docs: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private let id : String
    
    init(originalOccasion: OccasionRecord) {
        self.originalOccasion = originalOccasion
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        id = UUID().uuidString
        assetsFolderUrl = documentsUrl.appendingPathComponent(id)
        try! FileManager.default.createDirectory(at: assetsFolderUrl, withIntermediateDirectories: false, attributes: nil)
		
		if !originalOccasion.soundtracks.isEmpty {
			let index = Int(arc4random_uniform(UInt32(originalOccasion.soundtracks.count)));
			soundtrackId = originalOccasion.soundtracks[index].id;
		}
    }
    
    // MARK: Cover
    var coverRelPath : String {
        return assetsFolderRelUrl.appendingPathComponent("cover").absoluteString
    }
    var coverUrl : URL {
        return docs.appendingPathComponent(coverRelPath)
    }
    private(set) var coverIndex: Int?
    
    func setCover(with data: Data, at index: Int) {
        coverIndex = index
        try! data.write(to: coverUrl)
    }
	
	private (set) var soundtrackId: Int?;
	var soundtrack: OccasionSoundtrack? {
		return originalOccasion.soundtracks.filter{ $0.id == soundtrackId }.first;
	}
    
    // MARK: Photos
    
    private var  photoUrlsDict : [Int: String] = [:]
    
    var photosLocalIds : [String] = []
    
    var photoUrls : [URL] {
        return photoUrlsDict.sorted {$0.0 < $1.0}.map {docs.appendingPathComponent($0.value)}
    }
    
    var photoRelPaths : [String] {
        return photoUrlsDict.sorted {$0.0 < $1.0}.map {$0.value}
    }
    
    func removePhotos() {
        photoUrls.forEach { (photoUrl) in
            try? FileManager.default.removeItem(at: photoUrl)
        }
        photosLocalIds.removeAll()
        photoUrlsDict.removeAll()
    }
    
    func addPhoto(data: Data, at index: Int) {
        let relPath = assetsFolderRelUrl.appendingPathComponent("photo\(index)").absoluteString
        let photoUrl = docs.appendingPathComponent(relPath)
        photoUrlsDict[index] = relPath
        try! data.write(to: photoUrl)
    }
    
    // MARK: Video
    
    var trimPoints : (CMTime, CMTime)?
    
    var videoRelPath : String {
        return assetsFolderRelUrl.appendingPathComponent("video.mov").absoluteString
    }
    
    var videoUrl : URL {
        return docs.appendingPathComponent(videoRelPath)
    }
    
    var trimmedVideoUrl : URL {
        return assetsFolderUrl.appendingPathComponent("final_video.mov")
    }
    
    func replaceVideoWithTrimmed() {
		let _ = try! FileManager.default.replaceItemAt(videoUrl, withItemAt: trimmedVideoUrl, options: .usingNewMetadataOnly);
    }
    
    func removeVideo() {
        try? FileManager.default.removeItem(at: videoUrl)
    }
    
    // MARK: Final visheo
    
    var visheoRelPath : String {
        return assetsFolderRelUrl.appendingPathComponent("visheo.mov").absoluteString
    }
}

extension VisheoRenderingAssets {
    var creationInfo : VisheoCreationInfo {
        return VisheoCreationInfo(visheoId: id,
                                  coverId: 2,
                                  picturesCount: photoUrls.count,
                                  soundtrackId: 23,
                                  premium: false,
                                  coverRelPath: coverRelPath,
                                  soundtrackRelPath: "", //TODO: Add correct soundtrack relative path
                                  videoRelPath: videoRelPath,
                                  photoRelPaths: photoRelPaths,
                                  visheoRelPath: visheoRelPath)
    }
}
