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
	var canCancelSelection: Bool { get }
    
    var preselectedCoverIndex : Int {get set}
	
	func cancel()
    func selectCover()
	var didChangeCallback: (() -> Void)? { get set }
}

class VisheoSelectCoverViewModel : SelectCoverViewModel {
    var hideBackButton: Bool {
        return editMode
    }
	
	var canCancelSelection: Bool {
		return editMode;
	}
    
    var showProgressCallback: ((Bool) -> ())?
    var warningAlertHandler: ((String) -> ())?
	var didChangeCallback: (() -> Void)?
    
    var preselectedCoverIndex: Int {
        didSet {
            NotificationCenter.default.post(name: .preselectedCoverChanged, object: self)
        }
    }
    
    weak var router: SelectCoverRouter?
    let occasion : OccasionRecord
    let permissionsService : AppPermissionsService
	let soundtracksService: SoundtracksService
	let loggingService: EventLoggingService;
	private let appStateService: AppStateService;
    let assets: VisheoRenderingAssets
    let editMode : Bool
    
	init(occasion: OccasionRecord,
		 assets: VisheoRenderingAssets,
		 permissionsService: AppPermissionsService,
		 soundtracksService: SoundtracksService,
		 loggingService: EventLoggingService,
		 appStateService: AppStateService,
		 editMode: Bool = false)
	{
        self.occasion = occasion
        self.permissionsService = permissionsService
		self.soundtracksService = soundtracksService
		self.loggingService = loggingService;
		self.appStateService = appStateService;
        self.assets = assets
        self.editMode = editMode
        
        preselectedCoverIndex = assets.coverIndex ?? 0
		
		NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
			if let reachable = self?.appStateService.isReachable, reachable {
				self?.didChangeCallback?();
			}
		}
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self);
	}
    
    func coverViewModel(at index: Int) -> CoverCellViewModel {
        return VisheoCoverCellViewModel(imageURL: occasion.covers[index].previewUrl)
    }
    
    var coversNumber: Int {
        return occasion.covers.count
    }
	
	func cancel() {
		router?.goBack(wit: assets);
	}
    
    func selectCover() {
        showProgressCallback?(true)
        let selectedCover = occasion.covers[preselectedCoverIndex]
        
        SDImageCache.shared().config.shouldCacheImagesInMemory = false
        SDWebImageManager.shared().loadImage(with: selectedCover.url, options: [], progress: nil) { (image, data, error, cacheType, success, url) in
            self.showProgressCallback?(false)
            if let coverData = data {
                self.assets.setCover(with: coverData, at: self.preselectedCoverIndex, id: selectedCover.id, url: selectedCover.previewUrl)
                self.navigateFurther(with: self.assets)
            } else if let image = image, let coverData = UIImageJPEGRepresentation(image, 1.0) {
                self.assets.setCover(with: coverData, at: self.preselectedCoverIndex, id: selectedCover.id, url: selectedCover.previewUrl)
                self.navigateFurther(with: self.assets)
            }
            else if let error = error {
                self.warningAlertHandler?(error.localizedDescription)
            }
            SDImageCache.shared().config.shouldCacheImagesInMemory = true
        }
    }
    
    func navigateFurther(with assets: VisheoRenderingAssets)
	{
		loggingService.log(event: CoverSelectedEvent(), id: assets.creationInfo.visheoId);
		
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
