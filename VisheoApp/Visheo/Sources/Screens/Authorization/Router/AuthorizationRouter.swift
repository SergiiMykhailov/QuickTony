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
    
    let finishAuthCallback : (()->())?
    
    public init(dependencies: RouterDependencies, finishCallback: (()->())? = nil) {
        self.dependencies = dependencies
        self.finishAuthCallback = finishCallback
    }
    
    func start(with viewController: AuthorizationViewController, anonymousAllowed: Bool = true) {
        let vm = VisheoAutorizationViewModel(authService: dependencies.authorizationService, anonymousAllowed: anonymousAllowed)
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
            let router = VisheoSignInRouter(dependencies: dependencies, finishCallback: finishAuthCallback)
            router.start(with: signInController)
        case .showSignUp:
            let signUpController = segue.destination as! SignUpViewController
            let router = VisheoSignUpRouter(dependencies: dependencies, finishCallback: finishAuthCallback)
            router.start(with: signUpController)
        case .showMainScreen:
            dependencies.routerAssembly.assembleMainScreen(on: segue.destination, with: dependencies)
        }
    }
}

extension VisheoAuthorizationRouter {
    func showMainScreen() {
        if finishAuthCallback != nil {
            finishAuthCallback?()
        } else {
            controller?.performSegue(SegueList.showMainScreen, sender: nil)
        }
    }
    
    func showSignIn() {
        controller?.performSegue(SegueList.showSignIn, sender: nil)
    }
    
    func showSignUp() {
        controller?.performSegue(SegueList.showSignUp, sender: nil)
    }
}

