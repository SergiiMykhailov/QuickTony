//
//  LaunchProxyRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol LaunchProxyRouter: FlowRouter {
    func showOnboarding()
    func showLogin()
    func showMainScreen()
    
    func showTestScreen()
}

class DefaultLaunchProxyRouter : LaunchProxyRouter {
    enum SegueList: String, SegueListType {
        case showOnboarding = "showOnboarding"
        case showLogin      = "showLogin"
        case showMainScreen = "showMainScreen"
        case showTest       = "showTest"
    }
    
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: LaunchProxyViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: LaunchProxyViewController) {
        let vm = VisheoLaunchProxyViewModel(appState: dependencies.appStateService, authService: dependencies.authorizationService)
        viewModel = vm
        vm.router = self
        self.controller = viewController
        viewController.configure(viewModel: vm, router: self)
        
        vm.launch()
    }
    
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueList = SegueList(segue: segue) else {
            return
        }
        
        switch segueList {
        case .showOnboarding:
            let onboardingController = segue.destination as! OnboardingViewController            
            let router    = VisheoOnboardingRouter(dependencies: dependencies)
            router.start(with: onboardingController)
        case .showLogin:
            let loginController = (segue.destination as! UINavigationController).viewControllers[0] as! AuthorizationViewController
            let router = VisheoAuthorizationRouter(dependencies: dependencies)
            router.start(with: loginController)
        case .showMainScreen:
            let mainScreenController = (segue.destination as! UINavigationController).viewControllers[0] as! ChooseOccasionViewController
            let router = VisheoChooseOccasionRouter(dependencies: dependencies)
            router.start(with: mainScreenController)
        case .showTest:
            break
        }
    }
}

extension DefaultLaunchProxyRouter {
    func showLogin() {
        controller?.performSegue(SegueList.showLogin, sender: nil)
    }
    
    func showMainScreen() {
        controller?.performSegue(SegueList.showMainScreen, sender: nil)
    }
    
    func showOnboarding() {
        controller?.performSegue(SegueList.showOnboarding, sender: nil)
    }
    
    func showTestScreen() {
        controller?.performSegue(SegueList.showTest, sender: nil)
    }
}
