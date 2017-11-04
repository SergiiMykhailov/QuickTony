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
    func showSignIn()
    func showSignUp()
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
        case .showSignIn:
            let signInController = segue.destination as! SignInViewController
            let router = VisheoSignInRouter(dependencies: dependencies)
            router.start(with: signInController)
        case .showSignUp:
            let signUpController = segue.destination as! SignUpViewController
            let router = VisheoSignUpRouter(dependencies: dependencies)
            router.start(with: signUpController)
        default:
            break
        }
    }
}

extension VisheoAuthorizationRouter {
    func showMainScreen() {
        controller?.performSegue(SegueList.showMainScreen, sender: nil)
    }
    
    func showSignIn() {
        controller?.performSegue(SegueList.showSignIn, sender: nil)
    }
    
    func showSignUp() {
        controller?.performSegue(SegueList.showSignUp, sender: nil)
    }
}

