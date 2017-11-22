//
//  PreviewViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import UIKit

protocol PreviewViewModel : class {
    func editCover()
    func editPhotos()
    
    var phtos : [UIImage] {get}
}

class VisheoPreviewViewModel : PreviewViewModel {

    
    var phtos: [UIImage] {
        var phts = [UIImage]()
        for photoUrl in assets.photoUrls {
            phts.append(UIImage(data: FileManager.default.contents(atPath: photoUrl.path)!)!)
        }
        
        return phts
    }
    weak var router: PreviewRouter?
    let assets: VisheoRenderingAssets
    let permissionsService : AppPermissionsService
    
    init(assets: VisheoRenderingAssets, permissionsService: AppPermissionsService) {
        self.assets = assets
        self.permissionsService = permissionsService
    }
    
    func editCover() {
        router?.showCoverEdit(with: assets)
    }
    
    func editPhotos() {
        if permissionsService.galleryAccessAllowed {
            router?.showPhotosEdit(with: assets)
        } else {
            router?.showPhotoPermissions(with: assets)
        }
    }
}
