//
//  OnboardingRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol OnboardingRouter: FlowRouter {
    func showLogin()
    func showMainScreen()
}

class VisheoOnboardingRouter : OnboardingRouter {
    enum SegueList: String, SegueListType {
        case showLogin      = "showLogin"
        case showMainScreen = "showMainScreen"
    }
    
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: OnboardingViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: OnboardingViewController) {
        let vm = VisheoOnboardingViewModel(appState: dependencies.appStateService)
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
        case .showLogin:
            let loginController = (segue.destination as! UINavigationController).viewControllers[0] as! AuthorizationViewController
            let router = VisheoAuthorizationRouter(dependencies: dependencies)
            router.start(with: loginController)
        case .showMainScreen:
            let mainScreenController = (segue.destination as! UINavigationController).viewControllers[0] as! ChooseOccasionViewController
            let router = VisheoChooseOccasionRouter(dependencies: dependencies)
            router.start(with: mainScreenController)
        }
    }
}

extension VisheoOnboardingRouter {
    func showLogin() {
        self.controller?.performSegue(SegueList.showLogin, sender: nil)
    }
    
    func showMainScreen() {
        self.controller?.performSegue(SegueList.showMainScreen, sender: nil)
    }
}

