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
}

class DefaultLaunchProxyRouter : LaunchProxyRouter {
    enum SegueList: String, SegueListType {
        case showOnboarding = "showOnboarding"
        case showLogin      = "showLogin"
        case showMainScreen = "showMainScreen"
    }
    
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: LaunchProxyViewModel?
    
    func start(with viewController: LaunchProxyViewController) {
        let vm = LaunchProxyViewModel(userDefaults: UserDefaults.standard)
        viewModel = vm
        vm.router = self
        self.controller = viewController
        viewController.configure(viewModel: vm, router: self)
        
        vm.launch()
    }
    
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let _ = SegueList(segue: segue) else {
            return
        }
    }
}

extension DefaultLaunchProxyRouter {
    func showLogin() {
    }
    
    func showMainScreen() {
    }
    
    func showOnboarding() {
        controller?.performSegue(SegueList.showOnboarding, sender: nil)
    }
}
