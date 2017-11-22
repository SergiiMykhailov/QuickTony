//
//  PhotoPickerViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Photos

protocol PhotoPickerViewModel : LongFailableActionViewModel {
    func checkPhoto(id: String)
    func photoSelectionIndex(for id: String) -> Int?
    
    var hideNavigationButtons : Bool {get}
    var proceedText : String {get}
    var canProceed : Bool {get}
    func proceed()
    func skipPhotos()
    
    var didChange: (()->())? {get set}
}

class VisheoPhotoPickerViewModel : PhotoPickerViewModel {
    var hideNavigationButtons: Bool {
        return editMode
    }
    
    var showProgressCallback: ((Bool) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var didChange: (() -> ())? {
        didSet {
            didChange?()
        }
    }
    
    var proceedText: String {
        return String.localizedStringWithFormat(NSLocalizedString("Proceed with %d Photo(s)", comment: ""), selectedPhotos.count)
    }
    
    var canProceed: Bool {
        return selectedPhotos.count > 0 || editMode
    }
    
    weak var router: PhotoPickerRouter?
    var selectedPhotos : [String] = []
    private let maxPhotos = 5
    let assets: VisheoRenderingAssets
    let permissionsService: AppPermissionsService
    let editMode : Bool
    
    init(assets: VisheoRenderingAssets, permissionsService: AppPermissionsService, editMode: Bool = false) {
        self.assets = assets
        self.permissionsService = permissionsService
        selectedPhotos = assets.photosLocalIds
        self.editMode = editMode
    }
    
    func checkPhoto(id: String) {
        if let containedIndex = selectedPhotos.index(of: id) {
            selectedPhotos.remove(at: containedIndex)
            didChange?()
        } else if selectedPhotos.count < maxPhotos {
            selectedPhotos.append(id)
            didChange?()
        }
    }
    
    func photoSelectionIndex(for id: String) -> Int? {
        guard let index = selectedPhotos.index(of: id) else {return nil}
        return index + 1
    }
    
    func skipPhotos() {
        assets.removePhotos()
        showVideoScreen(with: assets)
    }
    
    func proceed() {
        showProgressCallback?(true)
        loadAssets {
            self.showProgressCallback?(false)
            self.showVideoScreen(with: self.assets)
        }
    }
    
    // MARK: Private
    
    private func showVideoScreen(with assets: VisheoRenderingAssets) {
        if editMode {
            router?.goBack(with: assets)
            return
        }
        
        if permissionsService.cameraAccessAllowed {
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
                                                            }
                                                            group.leave()
                })
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            self.assets.photosLocalIds = self.selectedPhotos
            completion()
        }
    }
}
