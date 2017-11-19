//
//  AppPermissionsService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Photos

protocol AppPermissionsService {
    var galleryAccessAllowed : Bool {get}
    var galleryAccessPending : Bool {get}
    
    var cameraAccessAllowed : Bool {get}
    var cameraAccessPending : Bool {get}
    
    func requestGalleryAccess(completion:  @escaping ()->())
    func requestCameraAccess(completion: @escaping ()->())
}


class VisheoAppPermissionsService: AppPermissionsService {
    var galleryAccessAllowed: Bool {
        return PHPhotoLibrary.authorizationStatus() == .authorized
    }
    
    var galleryAccessPending: Bool {
        return PHPhotoLibrary.authorizationStatus() == .notDetermined
    }
    
    var cameraAccessAllowed: Bool {
        let types = [AVMediaType.video, AVMediaType.audio];
        let unauthorized = types.filter{ AVCaptureDevice.authorizationStatus(for: $0) != .authorized }
        return unauthorized.isEmpty
    }
    
    var cameraAccessPending: Bool {
        let types = [AVMediaType.video, AVMediaType.audio];
        let pending = types.filter{ AVCaptureDevice.authorizationStatus(for: $0) == .notDetermined }
        return !pending.isEmpty
    }
    
    func requestGalleryAccess(completion: @escaping () -> ()) {
        PHPhotoLibrary.requestAuthorization { (status) in
            DispatchQueue.main.async(execute: completion)
        }
    }
    
    func requestCameraAccess(completion: @escaping ()->()) {
        let types = [AVMediaType.video, AVMediaType.audio];
        let requestGroup = DispatchGroup()
        
        for type in types {
            if AVCaptureDevice.authorizationStatus(for: type) == .notDetermined {
                requestGroup.enter()
                AVCaptureDevice.requestAccess(for: type, completionHandler: { _ in
                    requestGroup.leave()
                });
            }
        }
        
        requestGroup.notify(queue: DispatchQueue.main, execute: completion)
    }
}
