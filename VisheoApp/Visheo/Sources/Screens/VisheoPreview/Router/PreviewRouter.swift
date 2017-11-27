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
    
    func sendVisheo(with assets: VisheoRenderingAssets)
    func showRegistration(with assets: VisheoRenderingAssets)
    func showCardTypeSelection(with assets: VisheoRenderingAssets)
}

class VisheoPreviewRouter : PreviewRouter {
    enum SegueList: String, SegueListType {
        case showCoverEdit         = "showCoverEdit"
        case showPhotosEdit        = "showPhotosEdit"
        case showPhotoPermissions  = "showPhotoPermissions"
        case showVideoEdit         = "showVideoEdit"
        case showSendVisheo        = "showSendVisheo"
        case showRegistration      = "showRegistration"
        case showCardTypeSelection = "showCardTypeSelection"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: VisheoPreviewViewController?
    private(set) weak var viewModel: PreviewViewModel?
    private(set) var assets : VisheoRenderingAssets
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets) {
        self.dependencies = dependencies
        self.assets = assets
    }
    
    func start(with viewController: VisheoPreviewViewController) {
        let vm = VisheoPreviewViewModel(assets: assets,
                                        permissionsService: dependencies.appPermissionsService,
                                        authService: dependencies.authorizationService, purchasesInfo: dependencies.purchasesInfo)
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
        case .showSendVisheo:
            let sendController = segue.destination as! ShareVisheoViewController
            let sendRouter = ShareVisheoRouter(dependencies: dependencies)
            sendRouter.start(with: sendController, assets: sender as! VisheoRenderingAssets)
        case .showRegistration: fallthrough
        case .showCardTypeSelection:
            break //TODO: Implement real initalization
        }
    }
}

extension VisheoPreviewRouter {
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
    
    func sendVisheo(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showSendVisheo, sender: assets)
    }
    
    func showRegistration(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showRegistration, sender: assets)
    }
    
    func showCardTypeSelection(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showCardTypeSelection, sender: assets)
    }
}

