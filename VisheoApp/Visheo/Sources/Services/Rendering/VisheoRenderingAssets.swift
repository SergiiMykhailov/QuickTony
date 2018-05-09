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
    private enum Constants {
        static let videoName = "video.mov"
		static let backupVideoName = "video_backup.mov"
        static let visheoName = "visheo.mov"
    }
    
    let originalOccasion: OccasionRecord
    let assetsFolderUrl : URL
    var assetsFolderRelUrl : URL {
        return URL(string: id)!
    }
    
    var signature : String?
    
    private var docs: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    private let id : String
    
    static func deleteAssets(for id: String) {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let assetsFolderUrl = documentsUrl.appendingPathComponent(id)
        try? FileManager.default.removeItem(at: assetsFolderUrl)
    }
    
    static func videoRenderingUrl(for visheoId: String) -> URL {
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let assetsFolderUrl = documentsUrl.appendingPathComponent(visheoId)
        return assetsFolderUrl.appendingPathComponent(Constants.visheoName)
    }
    
    init(originalOccasion: OccasionRecord) {
        self.originalOccasion = originalOccasion
        let documentsUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        id = UUID().uuidString
        assetsFolderUrl = documentsUrl.appendingPathComponent(id)
        try! FileManager.default.createDirectory(at: assetsFolderUrl, withIntermediateDirectories: false, attributes: nil)
		
		if !originalOccasion.soundtracks.isEmpty {
			let index = Int(arc4random_uniform(UInt32(originalOccasion.soundtracks.count)));
			let soundtrackId = originalOccasion.soundtracks[index].id;
			setSoundtrack(.cached(id: soundtrackId, url: nil));
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
    private(set) var coverId: Int?
    private(set) var coverRemotePreviewUrl: URL?
    
    func setCover(with data: Data, at index: Int, id: Int, url: URL?) {
        coverIndex = index
        coverId = id
        coverRemotePreviewUrl = url
        try! data.write(to: coverUrl)
    }
	
	enum SoundtrackSelection
	{
		case none
		case fallback(url: URL?)
		case cached(id: Int, url: URL?)
	}
	
	private (set) var soundtrackId: Int?;
    private (set) var soundtrackName: String?
	
	private (set) var soundtrackSelection: SoundtrackSelection = .none;

    var soundtrackURL: URL? {
        if let relPath = soundtrackRelPath {
            return docs.appendingPathComponent(relPath)
        }
        return nil
    }
    
    var soundtrackRelPath : String? {
        if let name = soundtrackName {
            return assetsFolderRelUrl.appendingPathComponent(name).absoluteString
        }
        return nil
    }
	
	var selectedSoundtrack: OccasionSoundtrack? {
		return originalOccasion.soundtracks.filter{ $0.id == soundtrackId }.first;
	}
	
	func setSoundtrack(_ soundtrack: SoundtrackSelection) {
		soundtrackSelection = soundtrack;
		
		switch soundtrack {
			case .none:
				soundtrackId = nil;
				soundtrackName = nil;
			case .fallback(let url):
				soundtrackId = nil;
				soundtrackName = url?.lastPathComponent;
				if let soundUrl = url {
					try! copy(source: soundUrl, to: soundtrackURL!);
				}
			case .cached(let id, let url):
				soundtrackId = id;
				soundtrackName = url?.lastPathComponent;
				if let soundUrl = url {
					try! copy(source: soundUrl, to: soundtrackURL!);
				}
		}
	}
	
	private func copy(source: URL, to destination: URL) throws {
		if FileManager.default.fileExists(atPath: destination.path) {
			try FileManager.default.removeItem(at: destination);
		}
		
		try FileManager.default.copyItem(at: source, to: destination);
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
    
    var isVideoRecorded : Bool {
        return FileManager.default.fileExists(atPath: videoUrl.path)
    }
    
    var trimPoints : (CMTime, CMTime)?
    
    var videoRelPath : String {
        return assetsFolderRelUrl.appendingPathComponent(Constants.videoName).absoluteString
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
	
	var backupVideoRelPath : String {
		return assetsFolderRelUrl.appendingPathComponent(Constants.backupVideoName).absoluteString
	}
	
	var backupVideoUrl: URL {
		return docs.appendingPathComponent(backupVideoRelPath);
	}
	
	func backupOriginalVideo() {
		_ = try? FileManager.default.copyItem(at: videoUrl, to: backupVideoUrl);
	}
	
	func restoreOriginalVideo() {
		_ = try? FileManager.default.replaceItemAt(videoUrl, withItemAt: backupVideoUrl, options: .usingNewMetadataOnly);
	}
	
	func removeBackupVideo() {
		try? FileManager.default.removeItem(at: backupVideoUrl);
	}
    
    // MARK: Final visheo
    
    var visheoRelPath : String {
        return assetsFolderRelUrl.appendingPathComponent(Constants.visheoName).absoluteString
    }
}

extension VisheoRenderingAssets {
    var creationInfo : VisheoCreationInfo {
        return VisheoCreationInfo(visheoId: id,
                                  occasionName: originalOccasion.name,
                                  signature: signature,
                                  coverId: coverId ?? -1,
                                  coverRemotePreviewUrl: coverRemotePreviewUrl,
                                  picturesCount: photoUrls.count,
                                  soundtrackId: soundtrackId ?? -1,
                                  premium: false,
                                  free: false,
                                  coverRelPath: coverRelPath,
                                  soundtrackRelPath: soundtrackRelPath,
                                  videoRelPath: videoRelPath,
                                  photoRelPaths: photoRelPaths,
                                  visheoRelPath: visheoRelPath)
    }
}
