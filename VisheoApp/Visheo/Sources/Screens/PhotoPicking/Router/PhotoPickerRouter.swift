//
//  PhotoPickerRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PhotoPickerRouter: FlowRouter {
    func showCamera()
    func showCameraPermissions()
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
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets) {
        self.dependencies = dependencies
        self.assets = assets
    }
    
    func start(with viewController: PhotoPickerViewController) {
        let vm = VisheoPhotoPickerViewModel(assets: self.assets, permissionsService: dependencies.appPermissionsService)
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
            let cameraRouter = VisheoCameraRouter(dependencies: dependencies)
            cameraRouter.start(with: cameraController)
        case .showCameraPermissions:
            let cameraPermissionController = segue.destination as! CameraPermissionsViewController
            let cameraPermissionsRouter = VisheoCameraPermissionsRouter(dependencies: dependencies)
            cameraPermissionsRouter.start(with: cameraPermissionController)
        }
    }
}

extension VisheoPhotoPickerRouter {    
    func showCamera() {
        controller?.performSegue(SegueList.showCamera, sender: nil)
    }
    
    func showCameraPermissions() {
        controller?.performSegue(SegueList.showCameraPermissions, sender: nil)
    }
}

