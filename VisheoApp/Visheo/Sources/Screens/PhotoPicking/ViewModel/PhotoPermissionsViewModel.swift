//
//  PhotoPermissionsViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Photos

protocol PhotoPermissionsViewModel : class {
    func skipPhotos()
    func allowAccess()
}

class VisheoPhotoPermissionsViewModel : PhotoPermissionsViewModel {
    func skipPhotos() {
        //TODO: SHow video permissions/picker screen
    }
    
    func allowAccess() {
        if PHPhotoLibrary.authorizationStatus() == .authorized {
            self.router?.showPhotoLibrary()
        } else if PHPhotoLibrary.authorizationStatus() == .denied {
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
        } else {
            PHPhotoLibrary.requestAuthorization { (status) in
                DispatchQueue.main.async {
                    if status == .authorized {
                        self.router?.showPhotoLibrary()
                    }                    
                }
            }
        }
    }
    
    weak var router: PhotoPermissionsRouter?
    
    init() {
    }
}
