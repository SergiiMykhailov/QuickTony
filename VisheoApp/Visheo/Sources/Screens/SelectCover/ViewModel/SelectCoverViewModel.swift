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

protocol SelectCoverViewModel : class, ProgressGenerating, WarningAlertGenerating {
    func coverViewModel(at index: Int) -> CoverCellViewModel
    var coversNumber : Int {get}
    var hideBackButton: Bool {get}
    
    var preselectedCoverIndex : Int {get set}
    
    func selectCover()
}

class VisheoSelectCoverViewModel : SelectCoverViewModel {
    var hideBackButton: Bool {
        return editMode
    }
    
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
	let soundtracksService: SoundtracksService
    let assets: VisheoRenderingAssets
    let editMode : Bool
    
	init(occasion: OccasionRecord,
		 assets: VisheoRenderingAssets,
		 permissionsService: AppPermissionsService,
		 soundtracksService: SoundtracksService,
		 editMode: Bool = false)
	{
        self.occasion = occasion
        self.permissionsService = permissionsService
		self.soundtracksService = soundtracksService
        self.assets = assets
        self.editMode = editMode
        
        preselectedCoverIndex = assets.coverIndex ?? 0
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
                self.assets.setCover(with: coverData, at: self.preselectedCoverIndex)
                self.navigateFurther(with: self.assets)
            } else if let image = image, let coverData = UIImageJPEGRepresentation(image, 1.0) {
                self.assets.setCover(with: coverData, at: self.preselectedCoverIndex)
                self.navigateFurther(with: self.assets)
            }
            else if let error = error {
                self.warningAlertHandler?(error.localizedDescription)
            }
            SDImageCache.shared().config.shouldCacheImagesInMemory = true
        }
    }
    
    func navigateFurther(with assets: VisheoRenderingAssets) {
        if editMode {
            router?.goBack(wit: assets)
            return
        }
		
		if let soundtrack = assets.selectedSoundtrack {
			soundtracksService.download(soundtrack)
		}
        
        if permissionsService.galleryAccessAllowed {
            router?.showPhotoLibrary(with: assets)
        } else {
            router?.showPhotoPermissions(with: assets)
        }
    }
}
