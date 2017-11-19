//
//  PhotoPickerRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PhotoPickerRouter: FlowRouter {
}

class VisheoPhotoPickerRouter : PhotoPickerRouter {
    enum SegueList: String, SegueListType {
        case showVideo = "showVideo"
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
        let vm = VisheoPhotoPickerViewModel(assets: self.assets)
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
        default:
            break
        }
    }
}

extension VisheoPhotoPickerRouter {
}

