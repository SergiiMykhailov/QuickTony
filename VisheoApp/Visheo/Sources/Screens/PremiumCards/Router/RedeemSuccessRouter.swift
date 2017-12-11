//
//  RedeemSuccessRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


protocol RedeemSuccessRouter: FlowRouter {
    func showCreate()
    func showMenu()
}

class VisheoRedeemSuccessRouter : RedeemSuccessRouter {
    enum SegueList: String, SegueListType {
        case next
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: RedeemSuccessViewController?
    private(set) weak var viewModel: RedeemSuccessViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: RedeemSuccessViewController, redeemedCount: Int) {
        let vm = VisheoRedeemSuccessViewModel(with: redeemedCount)
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

extension VisheoRedeemSuccessRouter {
    func showCreate() {
        dependencies.routerAssembly.assembleCreateVisheoScreen(on: controller?.sideMenuController?.rootViewController as! UINavigationController, with: dependencies)
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }

}

