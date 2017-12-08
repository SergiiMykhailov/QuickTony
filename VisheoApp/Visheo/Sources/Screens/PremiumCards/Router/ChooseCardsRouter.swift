//
//  ChooseCardsRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ChooseCardsRouter: FlowRouter {
    func showMenu()
}

class VisheoChooseCardsRouter : ChooseCardsRouter {
    enum SegueList: String, SegueListType {
        case next
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: ChooseCardsViewController?
    private(set) weak var viewModel: ChooseCardsViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: ChooseCardsViewController, fromMenu: Bool) {
        let vm = VisheoChooseCardsViewModel(fromMenu: fromMenu, purchasesService: dependencies.premiumCardsService, purchasesInfo: dependencies.purchasesInfo)
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

extension VisheoChooseCardsRouter {
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
}

