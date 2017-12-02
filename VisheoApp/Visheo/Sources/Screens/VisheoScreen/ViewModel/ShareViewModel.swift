//
//  ShareVisheoViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Photos

enum VisheoCreationStatus {
    case rendering(progress: Double)
    case uploading(progress: Double)
    case ready
}

protocol ShareViewModel : class, AlertGenerating {
    var coverImageUrl : URL? {get}
    var visheoUrl : URL? {get}
    var visheoLink : String? {get}
    var showBackButton : Bool {get}
    
    var renderingTitle : String {get}
    var uploadingTitle : String {get}
    
    var creationStatusChanged : (()->())? {get set}
    var creationStatus : VisheoCreationStatus {get}
    
    func startRendering()
    
    var showRetryLaterError : ((String)->())? {get set}
    func retry()
    func tryLater()
    func showMenu()
    
    func saveVisheo()
    func deleteVisheo()
}

class ExistingVisheoShareViewModel: ShareViewModel {
    var showBackButton: Bool {
        return true
    }
    
    var coverImageUrl: URL? {
        return visheoRecord.coverUrl
    }
    
    var visheoUrl: URL? {
        if let localUrl = visheosCache.localUrl(for: visheoRecord.id) {
            return localUrl
        } else if let remoteUrl = visheoRecord.videoUrl {
            //Here we just start download visheo to use it next time. And return remote url to be shown in AVPlayer
            // If this will be not enough we ll be able to replace this with only one downoad to cache and than pass it to player
            visheosCache.downloadVisheo(with: visheoRecord.id, remoteUrl: remoteUrl)
        }
        return visheoRecord.videoUrl
    }
    
    var visheoLink: String? {
        return visheoRecord.visheoLink
    }
    
    var renderingTitle: String = ""
    var uploadingTitle: String = ""
    var creationStatus: VisheoCreationStatus = .ready
    func startRendering() {}
    func retry() {}
    func tryLater() {}
    
    var creationStatusChanged: (() -> ())?
    var successAlertHandler: ((String) -> ())?
    var warningAlertHandler: ((String) -> ())?
    var showRetryLaterError: ((String) -> ())?
    
    weak var router: ShareRouter?
    private let visheoRecord : VisheoRecord
    private let visheoService : CreationService
    private let visheosCache : VisheosCache
    
    init(record: VisheoRecord, visheoService: CreationService, cache: VisheosCache) {
        self.visheoRecord = record
        self.visheoService = visheoService
        self.visheosCache = cache
    }
    
    func showMenu() {}
    
    func deleteVisheo() {
        self.visheoService.deleteVisheo(with: visheoRecord.id)
        router?.goToRoot()
    }
    
    func saveVisheo() {
        if let visheoUrl = visheoUrl {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: visheoUrl)
            }) {[weak self] (success, error) in
                if success {
                    self?.successAlertHandler?(NSLocalizedString("Your visheo was saved to the gallery.", comment: "Successfully save visheo to gallery text"))
                } else {
                    self?.warningAlertHandler?(NSLocalizedString("Oops... Something went wrong.", comment: "Failed to save visheo to gallery text"))
                }
            }
        }
    }
}

class ShareVisheoViewModel : ShareViewModel {
    var successAlertHandler: ((String) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var showRetryLaterError: ((String) -> ())?
    
    var visheoUrl: URL?
    var visheoLink: String?
    
    var showBackButton: Bool {
        return false
    }    
    
    var coverImageUrl: URL? {
        return assets.coverUrl
    }
    
    var creationStatusChanged: (() -> ())? {
        didSet {
            creationStatusChanged?()
        }
    }
    
    var creationStatus: VisheoCreationStatus = .rendering(progress: 0.3) {
        didSet {
            creationStatusChanged?()
        }
    }
    
    var renderingTitle: String = NSLocalizedString("We are rendering your Visheo", comment: "rendering visheo progress title")
    
    var uploadingTitle: String = NSLocalizedString("We are uploading your Visheo", comment: "uploading visheo progress title")
    
    weak var router: ShareRouter?
    private let renderingService : RenderingService
    private let creationService : CreationService
    private let assets: VisheoRenderingAssets
    
    init(assets: VisheoRenderingAssets, renderingService: RenderingService, creationService: CreationService) {
        self.renderingService = renderingService
        self.assets = assets
        self.creationService = creationService
    }
    
    func retry() {
        creationService.retryCreation(for: assets.creationInfo.visheoId)
    }
    
    func tryLater() {
        router?.goToRoot()
    }
    
    func deleteVisheo() {
        self.creationService.deleteVisheo(with: assets.creationInfo.visheoId)
        router?.goToRoot()
    }
    
    func saveVisheo() {
        if let visheoUrl = visheoUrl {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: visheoUrl)
            }) {[weak self] (success, error) in
                if success {
                    self?.successAlertHandler?(NSLocalizedString("Your visheo was saved to the gallery.", comment: "Successfully save visheo to gallery text"))
                } else {
                    self?.warningAlertHandler?(NSLocalizedString("Oops... Something went wrong.", comment: "Failed to save visheo to gallery text"))
                }
            }
        }
    }
    
    func startRendering() {
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoRenderingProgress, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let progress = info[Notification.Keys.progress] as? Double,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.assets.creationInfo.visheoId == visheoId else {return}

            self?.creationStatus = .rendering(progress: progress)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoUploadingProgress, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let progress = info[Notification.Keys.progress] as? Double,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.assets.creationInfo.visheoId == visheoId else {return}
            
            self?.creationStatus = .uploading(progress: progress)        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationFailed, object: nil, queue: .main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.assets.creationInfo.visheoId == visheoId,
                let error = info[Notification.Keys.error] as? CreationError else {return}
            
            switch error {
            case .uploadFailed:
                strongSelf.showRetryLaterError?(NSLocalizedString("Upload error. Retry?", comment: "Upload visheo error"))
            case .renderFailed:
                strongSelf.showRetryLaterError?(NSLocalizedString("Render error. Retry?", comment: "Render visheo error"))
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationSuccess, object: nil, queue: .main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.assets.creationInfo.visheoId == visheoId else {return}
            
            strongSelf.visheoUrl = info[Notification.Keys.visheoUrl] as? URL
            strongSelf.visheoLink = info[Notification.Keys.visheoShortLink] as? String
            strongSelf.creationStatus = .ready
        }
        
        self.creationService.createVisheo(from: assets, premium: true)
    }
    
    func showMenu() {
        router?.showMenu()
    }
}
