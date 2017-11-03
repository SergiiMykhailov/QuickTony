//
//  AuthorizationRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


protocol AuthorizationRouter: FlowRouter {
    func showMainScreen()
}

class VisheoAuthorizationRouter : AuthorizationRouter {
    enum SegueList: String, SegueListType {
        case showSignIn = "showSignIn"
        case showSignUp = "showSignUp"
        case showMainScreen = "showMainScreen"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: AuthorizationViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: AuthorizationViewController) {
        let vm = VisheoAutorizationViewModel(authService: dependencies.authorizationService)
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

extension VisheoAuthorizationRouter {
    func showMainScreen() {
        controller?.performSegue(SegueList.showMainScreen, sender: nil)
    }
}

