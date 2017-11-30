//
//  MenuRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol MenuRouter: FlowRouter {
    func showCreateVisheo()
}

class VisheoMenuRouter : MenuRouter {
    enum SegueList: String, SegueListType {
        case showCreateScreen
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: MenuViewController?
    private(set) weak var viewModel: MenuViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: MenuViewController) {
        let vm = VisheoMenuViewModel(userInfo: dependencies.userInfoProvider)
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
        default:
            break
        }
    }
}

extension VisheoMenuRouter {
    func showCreateVisheo() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let chooseOccasionController = storyboard.instantiateViewController(withIdentifier: "ChooseOccasionViewController") as! ChooseOccasionViewController
        let mainRouter = VisheoChooseOccasionRouter(dependencies: dependencies)
        mainRouter.start(with: chooseOccasionController)
        
        let navigationController = controller?.sideMenuController?.rootViewController as! UINavigationController
        navigationController.setViewControllers([chooseOccasionController], animated: false)
        controller?.sideMenuController?.hideLeftView(animated: true, delay: 0.0, completionHandler: nil)
    }
}

