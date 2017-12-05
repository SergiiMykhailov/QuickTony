//
//  AccountRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol AccountRouter: FlowRouter {
    func showMenu()
    func showEdit(userName: String)
    func showRegistration()
}

class VisheoAccountRouter : AccountRouter {
    enum SegueList: String, SegueListType {
        case showEdit = "showEdit"
        case showRegistration = "showRegistration"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: AccountViewController?
    private(set) weak var viewModel: AccountViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: AccountViewController) {
        let vm = VisheoAccountViewModel(userInfo: dependencies.userInfoProvider, authService: dependencies.authorizationService)
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
        case .showEdit:
            let controller = segue.destination as! EditAccountViewController
            let router = VisheoEditAccountRouter(dependencies: dependencies)
            router.start(with: controller, userName: sender as! String)
        case .showRegistration:
            let loginController = (segue.destination as! UINavigationController).viewControllers[0] as! AuthorizationViewController
            let router = VisheoAuthorizationRouter(dependencies: dependencies)
            router.start(with: loginController)
        }
    }
}

extension VisheoAccountRouter {
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
    
    func showEdit(userName: String) {
        controller?.performSegue(SegueList.showEdit, sender: userName)
    }
    
    func showRegistration() {
        controller?.performSegue(SegueList.showRegistration, sender: nil)
    }
}

