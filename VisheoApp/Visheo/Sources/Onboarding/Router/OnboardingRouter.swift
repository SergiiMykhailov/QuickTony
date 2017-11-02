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
    private(set) weak var viewModel: VisheoOnboardingViewModel?
    
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
        guard let _ = SegueList(segue: segue) else {
            return
        }
    }
}

extension VisheoOnboardingRouter {
    func showLogin() {
        self.controller?.performSegue(SegueList.showLogin, sender: nil)
    }
    
    func showMainScreen() {
    }
}

