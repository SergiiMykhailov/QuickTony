//
//  VisheoCreationService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/24/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase
import FirebaseStorage


struct VisheoCreationInfo : Codable {
    let visheoId : String
    
    let coverId : Int
    let picturesCount : Int
    let soundtrackId : Int    
    var premium: Bool = false
    
    var coverRelPath : String
    var soundtrackRelPath : String
    var videoRelPath : String
    var photoRelPaths : [String]
    
    var visheoRelPath : String
}

extension VisheoCreationInfo {
    var firebaseRecord: VisheoCreationService.Record {
        return ["coverId" : coverId,
                "picturesCount" : picturesCount,
                "soundtrackId" : soundtrackId]
    }
    private var docs: URL {
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
    
    var coverUrl : URL {
        return docs.appendingPathComponent(coverRelPath)
    }
    var soundtrackUrl : URL {
        return docs.appendingPathComponent(soundtrackRelPath)
    }
    
    var videoUrl : URL {
        return docs.appendingPathComponent(videoRelPath)
    }
    
    var photoUrls : [URL] {
        return photoRelPaths.map {
            docs.appendingPathComponent($0)
        }
    }
    
    var visheoURL : URL {
        return docs.appendingPathComponent(visheoRelPath)
    }
}

extension VisheoCreationInfo {
    var visheoCreated: Bool {
        return FileManager.default.fileExists(atPath: visheoURL.path)
    }
}

extension Notification.Name {
    static let visheoRenderingProgress = Notification.Name("visheoRenderingProgress")
    static let visheoUploadingProgress = Notification.Name("visheoUploadingProgress")
    
    static let visheoCreationSuccess = Notification.Name("visheoCreationSuccess")
    static let visheoCreationFailed = Notification.Name("visheoCreationFailed")
}

extension Notification.Keys {
    static let visheoId = "visheoId"
    static let progress = "progress"
    static let visheoUrl = "visheoUrl"
    static let visheoShortLink = "visheoShortLink"
}

enum CreationError : Error {
    case uploadFailed
    case renderFailed
}

protocol CreationService {
    func createVisheo(from assets:VisheoRenderingAssets, premium: Bool)
    func retryCreation(for visheoId: String)
}

class VisheoCreationService : CreationService {
    private enum StorageFolders {
        static let premium     = "PremiumVisheos"
        static let free        = "FreeVisheos"
    }
    typealias Record = [String: Any]
    
    private let unfinishedRecordsKey = "unfinishedRecords"
    
    private let userInfoProvider : UserInfoProvider
    private let cardsRef : DatabaseReference
    private let rendererService : RenderingService
    
    init(userInfoProvider: UserInfoProvider, rendererService : RenderingService) {
        self.userInfoProvider = userInfoProvider
        self.rendererService  = rendererService
        cardsRef              = Database.database().reference().child("cards")
        
        continueUnfinished()
    }
    
    func continueUnfinished() {
        let defaults = UserDefaults.standard
        guard let unfinishedRecords = defaults.object(forKey: unfinishedRecordsKey) as? Record else {return}
        
        for (_, value) in unfinishedRecords {
            if let creationInfo = try? PropertyListDecoder().decode(VisheoCreationInfo.self, from: value as! Data) {
                retry(creationInfo: creationInfo)
            }
        }
    }
    
    func unfinishedInfo(with id: String) -> VisheoCreationInfo? {
        let defaults = UserDefaults.standard
        guard let unfinishedRecords = defaults.object(forKey: unfinishedRecordsKey) as? Record,
        let infoData = unfinishedRecords[id] as? Data else {return nil}
        let creationInfo = try? PropertyListDecoder().decode(VisheoCreationInfo.self, from: infoData)        
        return creationInfo
    }
    
    func createVisheo(from assets: VisheoRenderingAssets, premium: Bool) {
        var info = assets.creationInfo
        info.premium = premium
        var visheoRecord = info.firebaseRecord
        visheoRecord["userId"] = self.userInfoProvider.userId
        self.cardsRef.child(info.visheoId).setValue(visheoRecord)
        save(unfinished: info)
        render(creationInfo: info)
    }
    
    func retryCreation(for visheoId: String) {
        if let info = unfinishedInfo(with: visheoId) {
            retry(creationInfo: info)
        }
    }
    
    func retry(creationInfo: VisheoCreationInfo) {
        if creationInfo.visheoCreated {
            upload(creationInfo: creationInfo)
        } else {
            render(creationInfo: creationInfo)
        }
    }
    
    private func save(unfinished creationInfo: VisheoCreationInfo) {
        let defaults = UserDefaults.standard
        var unfinishedRecords = defaults.object(forKey: unfinishedRecordsKey) as? Record
        if unfinishedRecords == nil {
            unfinishedRecords = Record()
        }
        
        let encodedInfo = try! PropertyListEncoder().encode(creationInfo)
        unfinishedRecords![creationInfo.visheoId] = encodedInfo
        defaults.set(unfinishedRecords, forKey: unfinishedRecordsKey)
        defaults.synchronize()
    }
    
    private func remove(unfinished creationInfo: VisheoCreationInfo) {
        let defaults = UserDefaults.standard
        var unfinishedRecords = defaults.object(forKey: unfinishedRecordsKey) as? Record
        guard unfinishedRecords != nil else {return}
        
        unfinishedRecords?.removeValue(forKey: creationInfo.visheoId)
        defaults.set(unfinishedRecords, forKey: unfinishedRecordsKey)
        defaults.synchronize()
    }
    
    private func render(creationInfo: VisheoCreationInfo) {
        self.notifyRendering(progress: 0.0, for: creationInfo.visheoId)
        rendererService.export(creationInfo: creationInfo , progress: { (progress) in
            self.notifyRendering(progress: progress, for: creationInfo.visheoId)
        }) { (url, error) in
            if let url = url {
                let error = self.save(visheo: url, for: creationInfo)
                
                if error != nil {
                    self.notifyError(error: CreationError.renderFailed, for: creationInfo.visheoId)
                } else {
                    self.cleanup(creationInfo: creationInfo)
                    self.upload(creationInfo: creationInfo)
                }
            } else {
                self.notifyError(error: CreationError.renderFailed, for: creationInfo.visheoId)
            }
        }
    }
    
    private func cleanup(creationInfo: VisheoCreationInfo) {
        try? FileManager.default.removeItem(at: creationInfo.coverUrl)
//        try? FileManager.default.removeItem(at: creationInfo.soundtrackUrl)
        creationInfo.photoUrls.forEach {
            try? FileManager.default.removeItem(at: $0)
        }
    }
    
    private func upload(creationInfo: VisheoCreationInfo) {
        let videoRef = Storage.storage().reference().child(refPath(for: creationInfo.visheoId, premium: true))

        self.notifyUploading(progress: 0.0, for: creationInfo.visheoId)
        let uploadTask = videoRef.putFile(from: creationInfo.visheoURL, metadata: nil)

        uploadTask.observe(.progress) { (snapshot) in
            if let uploadingProgress = snapshot.progress, uploadingProgress.totalUnitCount > 0 {
                let progress = Double(uploadingProgress.completedUnitCount) / Double(uploadingProgress.totalUnitCount)
                self.notifyUploading(progress: progress, for: creationInfo.visheoId)
            }
        }

        uploadTask.observe(.success) { snapshot in
            self.finalize(creationInfo: creationInfo, downloadUrl: snapshot.metadata?.downloadURL())
        }

        uploadTask.observe(.failure) { snapshot in
            self.notifyError(error: CreationError.uploadFailed, for: creationInfo.visheoId)
        }
    }
    
    private func finalize(creationInfo: VisheoCreationInfo, downloadUrl : URL?) {
        if let downloadUrl = downloadUrl {
            self.cardsRef.child(creationInfo.visheoId).child("downloadUrl").setValue(downloadUrl.absoluteString)
        }
        self.cardsRef.child(creationInfo.visheoId).child("visheoUrl").setValue(shortUrl(for: creationInfo.visheoId))
        remove(unfinished: creationInfo)
        notifySuccess(for: creationInfo.visheoId, visheoUrl: creationInfo.visheoURL, visheoLink: shortUrl(for: creationInfo.visheoId))
    }
    
    // MARK: Private
    
    private func notifyUploading(progress: Double, for visheoId: String) {
        let info = [Notification.Keys.progress : progress,
                    Notification.Keys.visheoId : visheoId] as [String : Any]
        NotificationCenter.default.post(name: .visheoUploadingProgress, object: self, userInfo: info)
    }
    
    private func notifyRendering(progress: Double, for visheoId: String) {
        let info = [Notification.Keys.progress : progress,
                    Notification.Keys.visheoId : visheoId] as [String : Any]
        NotificationCenter.default.post(name: .visheoRenderingProgress, object: self, userInfo: info)
    }
    
    private func notifySuccess(for visheoId: String, visheoUrl: URL, visheoLink: String) {
        let info = [Notification.Keys.visheoUrl : visheoUrl,
                    Notification.Keys.visheoShortLink : visheoLink,
                    Notification.Keys.visheoId : visheoId] as [String : Any]
        
        NotificationCenter.default.post(name: .visheoCreationSuccess, object: self, userInfo: info)
    }
    
    private func notifyError(error: Error?, for visheoId: String) {
        var info = [Notification.Keys.visheoId : visheoId] as [String : Any]
        if let error = error {
            info[Notification.Keys.error] = error
        }
        NotificationCenter.default.post(name: .visheoCreationFailed, object: self, userInfo: info)
    }
    
    private func save(visheo: URL, for creationInfo: VisheoCreationInfo) -> Error? {
        do {
            if FileManager.default.fileExists(atPath: creationInfo.visheoURL.path) {
                try FileManager.default.removeItem(at: creationInfo.visheoURL)
            }
            try FileManager.default.moveItem(at: visheo, to: creationInfo.visheoURL)
            return nil
        } catch {
            return error
        }
    }
    
    private func refPath(for id: String, premium: Bool) -> String {
        let folder = premium ? StorageFolders.premium : StorageFolders.free
        return "\(folder)/\(id)"
    }
    
    private func shortUrl(for id: String) -> String {
        return "https://visheo42.firebaseapp.com/?id=\(id)&cover=New%20Year/15684417_xxl"
//        return "http://visheo.com/\(id)/"
    }
}

