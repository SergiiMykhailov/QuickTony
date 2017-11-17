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
}

class VisheoPhotoPermissionsRouter : PhotoPermissionsRouter {
    enum SegueList: String, SegueListType {
        case showPhotoLibrary = "showPhotoLibrary"
    }
    let dependencies: RouterDependencies
    let assets : VisheoRenderingAssets
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: PhotoPermissionsViewModel?
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets) {
        self.dependencies = dependencies
        self.assets = assets
    }
    
    func start(with viewController: PhotoPermissionsViewController) {
        let vm = VisheoPhotoPermissionsViewModel()
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
            let pickerRouter = VisheoPhotoPickerRouter(dependencies: dependencies, assets: assets)
            pickerRouter.start(with: pickerController)
        }
    }
}

extension VisheoPhotoPermissionsRouter {
    func showPhotoLibrary() {
        controller?.performSegue(SegueList.showPhotoLibrary, sender: nil)
    }
}

