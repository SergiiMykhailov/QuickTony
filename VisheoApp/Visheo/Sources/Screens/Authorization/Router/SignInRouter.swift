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
    
    let finishAuthCallback : ((Bool)->())?
    
    public init(dependencies: RouterDependencies, finishCallback: ((Bool)->())? = nil) {
        self.dependencies = dependencies
        self.finishAuthCallback = finishCallback
    }
    
    func start(with viewController: SignInViewController) {
        let vm = VisheoSignInViewModel(userInputValidator: dependencies.userInputValidator, authService: dependencies.authorizationService, userNotificationService: dependencies.userNotificationsService)
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
            dependencies.routerAssembly.assembleMainScreen(on: segue.destination, with: dependencies)
        }
    }
}

extension VisheoSignInRouter {
    func showMainScreen() {
        if finishAuthCallback != nil {
            finishAuthCallback?(true)
        } else {
            controller?.performSegue(SegueList.showMainScreen, sender: nil)
        }
    }
}

