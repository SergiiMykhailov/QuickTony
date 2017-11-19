//
//  PhotoPermissionsViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PhotoPermissionsViewModel : class {
    func skipPhotos()
    func allowAccess()
}

class VisheoPhotoPermissionsViewModel : PhotoPermissionsViewModel {
    func skipPhotos() {
        if permissionsService.cameraAccessAllowed {
            router?.showCamera()
        } else {
            router?.showCameraPermissions()
        }
    }
    
    func allowAccess() {
        if permissionsService.galleryAccessAllowed {
            self.router?.showPhotoLibrary()
            return;
        }
        
        if !permissionsService.galleryAccessPending
        {
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
            return
        }
        
        permissionsService.requestGalleryAccess {
            if self.permissionsService.galleryAccessAllowed {
                self.router?.showPhotoLibrary()
            }
        }
    }
    
    weak var router: PhotoPermissionsRouter?
    let permissionsService: AppPermissionsService
    init(permissionsService: AppPermissionsService) {
        self.permissionsService = permissionsService
    }
}
