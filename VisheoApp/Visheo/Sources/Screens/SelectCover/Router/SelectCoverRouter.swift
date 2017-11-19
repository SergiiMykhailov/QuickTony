//
//  SelectCoverRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SelectCoverRouter: FlowRouter {
    func showPhotoLibrary(with assets: VisheoRenderingAssets)
    func showPhotoPermissions(with assets: VisheoRenderingAssets)
}

class VisheoSelectCoverRouter : SelectCoverRouter {
    enum SegueList: String, SegueListType {
        case showPhotoLibrary = "showPhotoLibrary"
        case showPhotoPermissions = "showPhotoPermissions"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: SelectCoverViewModel?
    
    let occasion : OccasionRecord
    
    public init(dependencies: RouterDependencies, occasion: OccasionRecord) {
        self.dependencies = dependencies
        self.occasion = occasion
    }
    
    func start(with viewController: SelectCoverViewController) {
        let vm = VisheoSelectCoverViewModel(occasion: self.occasion, permissionsService: dependencies.appPermissionsService)
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
        case .showPhotoPermissions:
            let photoPermissionsController = segue.destination as! PhotoPermissionsViewController
            let permissionsRouter = VisheoPhotoPermissionsRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets)
            permissionsRouter.start(with: photoPermissionsController)
        case .showPhotoLibrary:
            let pickerController = segue.destination as! PhotoPickerViewController
            let pickerRouter = VisheoPhotoPickerRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets)
            pickerRouter.start(with: pickerController)
        }
    }
}

extension VisheoSelectCoverRouter {
    func showPhotoLibrary(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showPhotoLibrary, sender: assets)
    }
    
    func showPhotoPermissions(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showPhotoPermissions, sender: assets)
    }
}

