//
//  ShareVisheoViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

enum VisheoCreationStatus {
    case rendering(progress: Double)
    case uploading(progress: Double)
    case ready
}

protocol ShareViewModel : class {
    var renderingTitle : String {get}
    var uploadingTitle : String {get}
    
    var creationStatusChanged : (()->())? {get set}
    var creationStatus : VisheoCreationStatus {get}
    
    func startRendering()
}

class ShareVisheoViewModel : ShareViewModel {
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
            //TODO: Add processing
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationSuccess, object: nil, queue: .main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.assets.creationInfo.visheoId == visheoId else {return}
            strongSelf.creationStatus = .ready
        }
        
        self.creationService.createVisheo(from: assets, premium: true)
    }
}
