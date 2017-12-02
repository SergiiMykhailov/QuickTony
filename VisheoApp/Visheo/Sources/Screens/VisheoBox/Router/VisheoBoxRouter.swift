//
//  VisheoBoxRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol VisheoBoxRouter: FlowRouter {
    func showMenu()
}

class VisheoListRouter : VisheoBoxRouter {
    enum SegueList: String, SegueListType {
        case next
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: VisheoBoxViewController?
    private(set) weak var viewModel: VisheoBoxViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: VisheoBoxViewController) {
        let vm = VisheoListViewModel(visheosList: dependencies.visheosListService)
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

extension VisheoListRouter {
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
}

