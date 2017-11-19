//
//  SelectCoverViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import SDWebImage

extension Notification.Name {
    static let preselectedCoverChanged = Notification.Name("preselectedCoverChanged")
}

protocol SelectCoverViewModel : LongFailableActionViewModel {
    func coverViewModel(at index: Int) -> CoverCellViewModel
    var coversNumber : Int {get}
    
    var preselectedCoverIndex : Int {get set}
    
    func selectCover()
}

class VisheoSelectCoverViewModel : SelectCoverViewModel {
    var showProgressCallback: ((Bool) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var preselectedCoverIndex: Int {
        didSet {
            NotificationCenter.default.post(name: .preselectedCoverChanged, object: self)
        }
    }
    
    weak var router: SelectCoverRouter?
    let occasion : OccasionRecord
    let permissionsService : AppPermissionsService
    
    init(occasion: OccasionRecord, permissionsService: AppPermissionsService) {
        self.occasion = occasion
        self.permissionsService = permissionsService
        preselectedCoverIndex = 0
    }
    
    func coverViewModel(at index: Int) -> CoverCellViewModel {
        return VisheoCoverCellViewModel(imageURL: occasion.covers[index].previewUrl)
    }
    
    var coversNumber: Int {
        return occasion.covers.count
    }
    
    func selectCover() {
        showProgressCallback?(true)
        let selectedCover = occasion.covers[preselectedCoverIndex]
        
        SDImageCache.shared().config.shouldCacheImagesInMemory = false
        SDWebImageManager.shared().loadImage(with: selectedCover.url, options: [], progress: nil) { (image, data, error, cacheType, success, url) in
            self.showProgressCallback?(false)
            if let coverData = data {
                let assets = VisheoRenderingAssets()
                assets.setCover(with: coverData)
                self.navigateFurther(with: assets)
            } else if let error = error {
                self.warningAlertHandler?(error.localizedDescription)
            }
            SDImageCache.shared().config.shouldCacheImagesInMemory = true
        }
    }
    
    func navigateFurther(with assets: VisheoRenderingAssets) {
        if permissionsService.galleryAccessAllowed {
            router?.showPhotoLibrary(with: assets)
        } else {
            router?.showPhotoPermissions(with: assets)
        }
    }
}
