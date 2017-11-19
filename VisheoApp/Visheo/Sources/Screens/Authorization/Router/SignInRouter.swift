//
//  SignInRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SignInRouter: FlowRouter {
    func showMainScreen()
}

class VisheoSignInRouter : SignInRouter {
    enum SegueList: String, SegueListType {
        case showMainScreen = "showMainScreen"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: SignInViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: SignInViewController) {
        let vm = VisheoSignInViewModel(userInputValidator: dependencies.userInputValidator, authService: dependencies.authorizationService)
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
        case .showMainScreen:
            let mainScreenController = (segue.destination as! UINavigationController).viewControllers[0] as! ChooseOccasionViewController
            let router = VisheoChooseOccasionRouter(dependencies: dependencies)
            router.start(with: mainScreenController)
        }
    }
}

extension VisheoSignInRouter {
    func showMainScreen() {
        controller?.performSegue(SegueList.showMainScreen, sender: nil)
    }
}
