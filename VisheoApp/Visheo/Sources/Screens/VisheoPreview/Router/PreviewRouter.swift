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
}

class VisheoPreviewRouter : PreviewRouter {
    enum SegueList: String, SegueListType {
        case showCoverEdit = "showCoverEdit"
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
        let vm = VisheoPreviewViewModel(assets: assets)
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
            let selectCoverRouter = VisheoSelectCoverRouter(dependencies: dependencies, occasion: assets.originalOccasion, assets: assets, callback: {self.assets = $0})
            selectCoverRouter.start(with: selectCoverScreen, editMode: true)
        }
    }
}

extension VisheoPreviewRouter {
    func showCoverEdit(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showCoverEdit, sender: assets)
    }
}

