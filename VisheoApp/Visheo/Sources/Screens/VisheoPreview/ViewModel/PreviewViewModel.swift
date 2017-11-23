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
    func editVideo()
    
    func sendVisheo()
    
    var assets : VisheoRenderingAssets {get}
}

class VisheoPreviewViewModel : PreviewViewModel {
    weak var router: PreviewRouter?
    let assets: VisheoRenderingAssets
    let permissionsService : AppPermissionsService
    let authService: AuthorizationService
    let purchasesInfo: UserPurchasesInfo
    
    init(assets: VisheoRenderingAssets,
         permissionsService: AppPermissionsService,
         authService: AuthorizationService,
         purchasesInfo: UserPurchasesInfo) {
        self.assets = assets
        self.permissionsService = permissionsService
        self.authService = authService
        self.purchasesInfo = purchasesInfo
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
    
    func editVideo() {
        router?.showVideoEdit(with: assets)
    }
    
    func sendVisheo() {
        if authService.isAnonymous {
            router?.showRegistration(with: assets)
        } else if purchasesInfo.premiumCardsNumber == 0 {
            router?.showCardTypeSelection(with: assets)
        } else {
            router?.sendVisheo(with: assets)
        }
        
    }
}
