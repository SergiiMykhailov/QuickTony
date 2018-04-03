//
//  PhotoPermissionsRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PhotoPermissionsRouter: FlowRouter {
    func showPhotoLibrary()
    func showCamera()
    func showCameraPermissions()
    func showTrimScreen()
    
    func goBack()
}

class VisheoPhotoPermissionsRouter : PhotoPermissionsRouter {
    enum SegueList: String, SegueListType {
        case showPhotoLibrary = "showPhotoLibrary"
        case showCamera = "showCameraScreen"
        case showCameraPermissions = "showCameraPermissionsScreen"
        case showTrimScreen = "showTrimScreen"
    }
    let dependencies: RouterDependencies
    let assets : VisheoRenderingAssets
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: PhotoPermissionsViewModel?
    var editMode : Bool = false
    let pickerCallback: ((VisheoRenderingAssets)->())?
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets, callback: ((VisheoRenderingAssets)->())? = nil) {
        self.dependencies = dependencies
        self.assets = assets
        self.pickerCallback = callback
    }
    
    func start(with viewController: PhotoPermissionsViewController, editMode: Bool = false) {
        self.editMode = editMode
        let vm = VisheoPhotoPermissionsViewModel(permissionsService: dependencies.appPermissionsService, editMode: editMode, videoRecorded: assets.isVideoRecorded)
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
        case .showPhotoLibrary:
            let pickerController = segue.destination as! PhotoPickerViewController
            let pickerRouter = VisheoPhotoPickerRouter(dependencies: dependencies, assets: assets, callback: pickerCallback)
            pickerRouter.start(with: pickerController, editMode: editMode)
        case .showCamera:
            let cameraController = segue.destination as! CameraViewController
            let cameraRouter = VisheoCameraRouter(dependencies: dependencies, assets: assets)
            cameraRouter.start(with: cameraController)
        case .showCameraPermissions:
            let cameraPermissionController = segue.destination as! CameraPermissionsViewController
            let cameraPermissionsRouter = VisheoCameraPermissionsRouter(dependencies: dependencies, assets: assets)
            cameraPermissionsRouter.start(with: cameraPermissionController)
        case .showTrimScreen:
            let trimmingController = segue.destination as! VideoTrimmingViewController
            let trimmingRouter = VisheoVideoTrimmingRouter(dependencies: dependencies, assets: assets)
            trimmingRouter.start(with: trimmingController)
        }
    }
}

extension VisheoPhotoPermissionsRouter {
    func showPhotoLibrary() {
        controller?.performSegue(SegueList.showPhotoLibrary, sender: nil)
    }
    
    func showCamera() {
        controller?.performSegue(SegueList.showCamera, sender: nil)
    }
    
    func showCameraPermissions() {
        controller?.performSegue(SegueList.showCameraPermissions, sender: nil)
    }
    
    func showTrimScreen() {
        controller?.performSegue(SegueList.showTrimScreen, sender: nil)
    }
    
    func goBack() {
        controller?.dismiss(animated: true, completion: nil)
    }
}

