//
//  EditAccountRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol EditAccountRouter: FlowRouter {
    func showRegistration()
}

class VisheoEditAccountRouter : EditAccountRouter {
    enum SegueList: String, SegueListType {
        case showRegistration = "showRegistration"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: EditAccountViewController?
    private(set) weak var viewModel: EditAccountViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: EditAccountViewController, userName: String) {
        let vm = VisheoEditAccountViewModel(userName: userName, authService: dependencies.authorizationService)
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
        case .showRegistration:
            let loginController = (segue.destination as! UINavigationController).viewControllers[0] as! AuthorizationViewController
            let router = VisheoAuthorizationRouter(dependencies: dependencies)
            router.start(with: loginController)
        }
    }
}

extension VisheoEditAccountRouter {
    func showRegistration() {
        controller?.performSegue(SegueList.showRegistration, sender: nil)
    }
}

