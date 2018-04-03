//
//  PhotoPickerViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Photos


enum PhotoPickerError: Error {
	case maxPhotosReached(max: Int)
}

protocol PhotoPickerViewModel : class, ProgressGenerating, WarningAlertGenerating {
    func checkPhoto(asset: PHAsset)
	var selectedPhotos : [String] { get }
    func photoSelectionIndex(for id: String) -> Int?
    
    var hideNavigationButtons : Bool {get}
	var canCancelSelection: Bool { get }
	var canSkipSelection: Bool { get }
    var proceedText : String {get}
    var canProceed : Bool {get}
    func proceed()
    func skipPhotos()
	func cancel()
    
    var didChange: ((PHAsset?)->())? {get set}
	var errorGenerated: ((Error)->())? {get set}
}

class VisheoPhotoPickerViewModel : PhotoPickerViewModel {
    var hideNavigationButtons: Bool {
        return editMode
    }
	
	var canSkipSelection: Bool {
		return !editMode;
	}
	
	var canCancelSelection: Bool {
		return editMode;
	}
    
    var showProgressCallback: ((Bool) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var didChange: ((PHAsset?) -> ())? {
        didSet {
            didChange?(nil)
        }
    }
	
	var errorGenerated: ((Error) -> ())?
    
    var proceedText: String {
        return String.localizedStringWithFormat(NSLocalizedString("Proceed with %d Photo(s)", comment: ""), selectedPhotos.count)
    }
    
    var canProceed: Bool {
        return selectedPhotos.count > 0 || editMode
    }
    
    weak var router: PhotoPickerRouter?
    var selectedPhotos : [String] = []
    let assets: VisheoRenderingAssets
    let permissionsService: AppPermissionsService
	let appStateService: AppStateService
	let loggingService: EventLoggingService
    let editMode : Bool
    
	init(assets: VisheoRenderingAssets,
		 permissionsService: AppPermissionsService,
		 appStateService: AppStateService,
		 loggingService: EventLoggingService,
		 editMode: Bool = false) {
        self.assets = assets
        self.permissionsService = permissionsService
		self.appStateService = appStateService;
		self.loggingService = loggingService;
        selectedPhotos = assets.photosLocalIds
        self.editMode = editMode
    }
    
    func checkPhoto(asset: PHAsset) {
        if let containedIndex = selectedPhotos.index(of: asset.localIdentifier) {
            selectedPhotos.remove(at: containedIndex)
            didChange?(asset)
        } else if selectedPhotos.count < maxPhotos {
            selectedPhotos.append(asset.localIdentifier)
            didChange?(asset)
		} else {
			errorGenerated?(PhotoPickerError.maxPhotosReached(max: maxPhotos))
		}
    }
    
    func photoSelectionIndex(for id: String) -> Int? {
        guard let index = selectedPhotos.index(of: id) else {return nil}
        return index + 1
    }
	
	func cancel() {
		router?.goBack(with: assets)
	}
    
    func skipPhotos() {
        assets.removePhotos()
        showVideoScreen(with: assets)
		loggingService.log(event: PhotosSkippedEvent(), id: assets.creationInfo.visheoId)
    }
    
    func proceed() {
        showProgressCallback?(true)
        loadAssets {
            self.showProgressCallback?(false)
            self.showVideoScreen(with: self.assets)
			self.loggingService.log(event: PhotosSelectedEvent(count: self.selectedPhotos.count), id: self.assets.creationInfo.visheoId)
        }
    }
    
    // MARK: Private
	
	private var maxPhotos: Int {
		return appStateService.appSettings.maxSelectablePhotos;
	}
    
    private func showVideoScreen(with assets: VisheoRenderingAssets) {
        if editMode {
            router?.goBack(with: assets)
            return
        }
        
        if assets.isVideoRecorded {
            router?.showTrimScreen(with: assets)
        } else if permissionsService.cameraAccessAllowed {
            router?.showCamera(with: assets)
        } else {
            router?.showCameraPermissions(with: assets)
        }
    }
    
    func loadAssets(completion: @escaping ()->()) {
        let group = DispatchGroup()
		let options = PHImageRequestOptions();
		options.isNetworkAccessAllowed = true;
        assets.removePhotos()
        for (index, assetLocalId) in selectedPhotos.enumerated() {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalId], options: nil)
            if let asset = result.firstObject {
                
                group.enter()
                PHImageManager.default().requestImageData(for: asset,
                                                          options: options,
                                                          resultHandler: { (data, mimetype, orientation, options) in
                                                            if let photoData = data {
                                                                self.assets.addPhoto(data: photoData, at: index)
															} else {
																print("Failed to load data for asset \(assetLocalId) \(String(describing: options))");
															}
                                                            group.leave()
                })
			} else {
				print("Failed to load asset \(assetLocalId)");
			}
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.assets.photosLocalIds = self.selectedPhotos
            completion()
        }
    }
}
