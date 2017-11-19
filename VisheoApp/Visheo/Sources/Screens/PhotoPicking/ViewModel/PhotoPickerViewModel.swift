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
    
    var proceedText : String {get}
    var canProceed : Bool {get}
    func proceed()
    func skipPhotos()
    
    var didChange: (()->())? {get set}
}

class VisheoPhotoPickerViewModel : PhotoPickerViewModel {
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
        return selectedPhotos.count > 0
    }
    
    weak var router: PhotoPickerRouter?
    var selectedPhotos : [String] = []
    private let maxPhotos = 5
    let assets: VisheoRenderingAssets
    let permissionsService: AppPermissionsService
    
    init(assets: VisheoRenderingAssets, permissionsService: AppPermissionsService) {
        self.assets = assets
        self.permissionsService = permissionsService
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
        showVideoScreen()
    }
    
    func proceed() {
        showProgressCallback?(true)
        loadAssets {
            self.showProgressCallback?(false)
            self.showVideoScreen()
        }
    }
    
    // MARK: Private
    
    private func showVideoScreen() {
        if permissionsService.cameraAccessAllowed {
            router?.showCamera()
        } else {
            router?.showCameraPermissions()
        }
    }
    
    func loadAssets(completion: @escaping ()->()) {
        let group = DispatchGroup()
        
        for (index, assetLocalId) in selectedPhotos.enumerated() {
            let result = PHAsset.fetchAssets(withLocalIdentifiers: [assetLocalId], options: nil)
            if let asset = result.firstObject {
                
                group.enter()
                PHImageManager.default().requestImageData(for: asset,
                                                          options: nil,
                                                          resultHandler: { (data, mimetype, orientation, options) in
                                                            if let photoData = data {
                                                                self.assets.addPhoto(data: photoData, at: index)
                                                            }
                                                            group.leave()
                })
            }
        }
        
        group.notify(queue: DispatchQueue.main) {
            completion()
        }
    }
}
