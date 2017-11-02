//
//  AuthorizationRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


protocol AuthorizationRouter: FlowRouter {
}

class VisheoAuthorizationRouter : AuthorizationRouter {
    enum SegueList: String, SegueListType {
        case showSignIn = "showSignIn"
        case showSignUp = "showSignUp"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: AuthorizationViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: UIViewController) {
        let vm = VisheoAutorizationViewModel()
        viewModel = vm
        vm.router = self
        self.controller = viewController
//        viewController.configure(viewModel: vm, router: self)
    }
    
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let _ = SegueList(segue: segue) else {
            return
        }
    }
}

extension VisheoAuthorizationRouter {
}

