//
//  PreviewRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PreviewRouter: FlowRouter {
    func showCoverEdit(with assets: VisheoRenderingAssets)
    func showPhotosEdit(with assets: VisheoRenderingAssets)
    func showPhotoPermissions(with assets: VisheoRenderingAssets)
    func showVideoEdit(with assets: VisheoRenderingAssets)
	func showSoundtrackEdit(with assets: VisheoRenderingAssets)
    
    func sendVisheo(with assets: VisheoRenderingAssets, premium: Bool)
    func showRegistration(with callback: ((Bool)->())?)
    func showCardTypeSelection(with assets: VisheoRenderingAssets)
}

class VisheoPreviewRouter : PreviewRouter {
    enum SegueList: String, SegueListType {
        case showCoverEdit         = "showCoverEdit"
        case showPhotosEdit        = "showPhotosEdit"
        case showPhotoPermissions  = "showPhotoPermissions"
        case showVideoEdit         = "showVideoEdit"
		case showSoundtrackEdit    = "showSoundtrackEdit"
        case showSendVisheo        = "showSendVisheo"
        case showRegistration      = "showRegistration"
        case showCardTypeSelection = "showCardTypeSelection"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: VisheoPreviewViewController?
    private(set) weak var viewModel: PreviewViewModel?
	
	private(set) var assets : VisheoRenderingAssets {
		didSet {
			viewModel?.handleAssetsUpdate(assets);
		}
	}
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets) {
        self.dependencies = dependencies
        self.assets = assets
    }
    
    func start(with viewController: VisheoPreviewViewController) {
        let vm = VisheoPreviewViewModel(assets: assets,
                                        permissionsService: dependencies.appPermissionsService,
                                        authService: dependencies.authorizationService,
										purchasesInfo: dependencies.purchasesInfo,
										appStateService: dependencies.appStateService,
										soundtracksService: dependencies.soundtracksService,
                                        premCardsService: dependencies.premiumCardsService)
        viewModel = vm
        vm.router = self
        self.controller = viewController
        viewController.configure(viewModel: vm, router: self)
    }
    
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueList = SegueList(segue: segue) else {
            return
        }
        switch segueList {
        case .showCoverEdit:
            let selectCoverScreen = (segue.destination as! UINavigationController).viewControllers[0] as! SelectCoverViewController
            let selectCoverRouter = VisheoSelectCoverRouter(dependencies: dependencies, occasion: assets.originalOccasion, assets: sender as? VisheoRenderingAssets, callback: {self.assets = $0})
            selectCoverRouter.start(with: selectCoverScreen, editMode: true)
        case .showPhotosEdit:
            let editPhotosScreen = (segue.destination as! UINavigationController).viewControllers[0] as! PhotoPickerViewController
            let editPhotosRouter = VisheoPhotoPickerRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets, callback: {self.assets = $0})
            editPhotosRouter.start(with: editPhotosScreen, editMode: true)
        case .showPhotoPermissions:
            let photoPermissionsScreen = (segue.destination as! UINavigationController).viewControllers[0] as! PhotoPermissionsViewController
            let photoPermissionsRouter = VisheoPhotoPermissionsRouter(dependencies: dependencies, assets: assets, callback: {self.assets = $0})
            photoPermissionsRouter.start(with: photoPermissionsScreen, editMode: true)
        case .showVideoEdit:
            let editVideoScreen = (segue.destination as! UINavigationController).viewControllers[0] as! VideoTrimmingViewController
            let editVideoRouter = VisheoVideoTrimmingRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets, callback: {self.assets = $0})
            editVideoRouter.start(with: editVideoScreen, editMode: true)
		case .showSoundtrackEdit:
			let editSoundtrackScreen = (segue.destination as! UINavigationController).viewControllers[0] as! SelectSoundtrackViewController;
			let editSoundtrackRouter = VisheoSelectSoundtrackRouter(dependencies: dependencies, occasion: assets.originalOccasion, assets: sender as! VisheoRenderingAssets, callback: {self.assets = $0})
			editSoundtrackRouter.start(with: editSoundtrackScreen)
        case .showSendVisheo:
            let sendController = segue.destination as! ShareVisheoViewController
            let sendRouter = ShareVisheoRouter(dependencies: dependencies)
            let userInfo = sender as! [String : Any]
            sendRouter.start(with: sendController,
                             assets: userInfo[Constants.assets] as! VisheoRenderingAssets,
                             sharePremium : userInfo[Constants.premium] as! Bool)
        case .showRegistration: 
            let authController = (segue.destination as! UINavigationController).viewControllers[0] as! AuthorizationViewController
            let authRouter = VisheoAuthorizationRouter(dependencies: dependencies) { result in
                self.controller?.dismiss(animated: true, completion: {
                    if let callback = sender as? ((Bool)->()) {
                        callback(result)
                    }
                })
            }
			authRouter.start(with: authController, anonymousAllowed: false, authReason: .sendVisheo);
        case .showCardTypeSelection:
            let purchaseController = segue.destination as! ChooseCardsViewController
            let purchaseRouter = VisheoChooseCardsRouter(dependencies: dependencies)
            purchaseRouter.start(with: purchaseController, fromMenu: false, with: (sender as! VisheoRenderingAssets))
        }
    }
}

extension VisheoPreviewRouter {
    private enum Constants {
        static let assets = "assets"
        static let premium = "premium"
    }
    
    func showCoverEdit(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showCoverEdit, sender: assets)
    }
    
    func showPhotosEdit(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showPhotosEdit, sender: assets)
    }
    
    func showPhotoPermissions(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showPhotoPermissions, sender: assets)
    }
    
    func showVideoEdit(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showVideoEdit, sender: assets)
    }
	
	func showSoundtrackEdit(with assets: VisheoRenderingAssets) {
		controller?.performSegue(SegueList.showSoundtrackEdit, sender: assets)
	}
    
    func sendVisheo(with assets: VisheoRenderingAssets, premium: Bool) {
        controller?.performSegue(SegueList.showSendVisheo, sender: [Constants.assets : assets, Constants.premium : premium])
    }
    
    func showRegistration(with callback: ((Bool)->())?) {
        controller?.performSegue(SegueList.showRegistration, sender: callback)
    }
    
    func showCardTypeSelection(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showCardTypeSelection, sender: assets)
    }
}

