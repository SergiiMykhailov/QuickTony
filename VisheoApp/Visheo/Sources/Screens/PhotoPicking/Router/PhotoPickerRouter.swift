//
//  PhotoPickerRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PhotoPickerRouter: FlowRouter {
    func showCamera(with assets: VisheoRenderingAssets)
    func showCameraPermissions(with assets: VisheoRenderingAssets)
    
    func goBack(with assets: VisheoRenderingAssets)
}

class VisheoPhotoPickerRouter : PhotoPickerRouter {
    enum SegueList: String, SegueListType {
        case showCamera = "showCameraScreen"
        case showCameraPermissions = "showCameraPermissionsScreen"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: PhotoPickerViewModel?
    let assets : VisheoRenderingAssets
    private let photosSelectedCallback  : ((VisheoRenderingAssets)->())?
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets,callback: ((VisheoRenderingAssets)->())? = nil) {
        self.dependencies = dependencies
        self.assets = assets
        self.photosSelectedCallback = callback
    }
    
    func start(with viewController: PhotoPickerViewController, editMode: Bool = false) {
		let vm = VisheoPhotoPickerViewModel(assets: self.assets,
											permissionsService: dependencies.appPermissionsService,
											appStateService: dependencies.appStateService,
											loggingService: dependencies.loggingService,
											editMode: editMode)
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
        case .showCamera:
            let cameraController = segue.destination as! CameraViewController
            let cameraRouter = VisheoCameraRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets)
            cameraRouter.start(with: cameraController)
        case .showCameraPermissions:
            let cameraPermissionController = segue.destination as! CameraPermissionsViewController
            let cameraPermissionsRouter = VisheoCameraPermissionsRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets)
            cameraPermissionsRouter.start(with: cameraPermissionController)
        }
    }
}

extension VisheoPhotoPickerRouter {    
    func showCamera(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showCamera, sender: assets)
    }
    
    func showCameraPermissions(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showCameraPermissions, sender: assets)
    }
    
    func goBack(with assets: VisheoRenderingAssets) {
        photosSelectedCallback?(assets)
        controller?.dismiss(animated: true, completion: nil)
    }
}

