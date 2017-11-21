//
//  PreviewRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PreviewRouter: FlowRouter {
}

class VisheoPreviewRouter : PreviewRouter {
    enum SegueList: String, SegueListType {
        case next
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: VisheoPreviewViewController?
    private(set) weak var viewModel: PreviewViewModel?
    let assets : VisheoRenderingAssets
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets) {
        self.dependencies = dependencies
        self.assets = assets
    }
    
    func start(with viewController: VisheoPreviewViewController) {
        let vm = VisheoPreviewViewModel()
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

extension VisheoPreviewRouter {
}

