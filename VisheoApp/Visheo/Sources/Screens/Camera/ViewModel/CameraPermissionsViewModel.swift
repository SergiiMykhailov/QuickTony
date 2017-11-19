//
//  CameraPermissionsViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/18/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol CameraPermissionsViewModel: class {
	func requestPermissions()
}

class VisheoCameraPermissionsViewModel: CameraPermissionsViewModel
{
	weak var router: CameraPermissionsRouter?
    
    let permissionsService: AppPermissionsService
    init(permissionsService: AppPermissionsService) {
        self.permissionsService = permissionsService
    }
	
	func requestPermissions()
	{
        if permissionsService.cameraAccessAllowed {
            self.router?.showCameraScreen()
            return;
        }
        
        if !permissionsService.cameraAccessPending
        {
            UIApplication.shared.open(URL(string:UIApplicationOpenSettingsURLString)!)
            return
        }
        
        permissionsService.requestCameraAccess {
            if self.permissionsService.cameraAccessAllowed {
                self.router?.showCameraScreen()
            }
        }
	}
	
}
