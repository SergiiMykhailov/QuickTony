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
    func showVisheoBox()
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
        showController(with: "ChooseOccasionViewController") { (controller) in
            let mainRouter = VisheoChooseOccasionRouter(dependencies: dependencies)
            mainRouter.start(with: controller as! ChooseOccasionViewController)
        }
    }
    
    func showVisheoBox() {
        showController(with: "VisheoBoxViewController") { (controller) in
            let router = VisheoListRouter(dependencies : dependencies)
            router.start(with: controller as! VisheoBoxViewController)
        }
    }
    
    
    private func showController(with id: String, storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil), setup: (UIViewController) -> ()) {
        let shownController = storyboard.instantiateViewController(withIdentifier: id)
        setup(shownController)        
        let navigationController = controller?.sideMenuController?.rootViewController as! UINavigationController
        navigationController.setViewControllers([shownController], animated: false)
        controller?.sideMenuController?.hideLeftView(animated: true, delay: 0.0, completionHandler: nil)
    }
}

