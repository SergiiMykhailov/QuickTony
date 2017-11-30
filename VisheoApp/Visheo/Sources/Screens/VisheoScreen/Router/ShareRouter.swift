//
//  ShareVisheoRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ShareRouter: FlowRouter {
    func goToRoot()
    func showMenu()
}

class ShareVisheoRouter : ShareRouter {
    enum SegueList: String, SegueListType {
        case next
    }
    
    let dependencies: RouterDependencies
    private(set) weak var controller: ShareVisheoViewController?
    private(set) weak var viewModel: ShareViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: ShareVisheoViewController, assets: VisheoRenderingAssets) {
        let vm = ShareVisheoViewModel(assets: assets, renderingService: dependencies.renderingService, creationService: dependencies.creationService)
        viewModel = vm
        vm.router = self
        self.controller = viewController
        viewController.configure(viewModel: vm, router: self)        
        vm.startRendering()
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

extension ShareVisheoRouter {
    func goToRoot() {
        controller?.navigationController?.popToRootViewController(animated: true)
    }
    
    func showMenu() {
         controller?.showLeftViewAnimated(self)
    }
}

