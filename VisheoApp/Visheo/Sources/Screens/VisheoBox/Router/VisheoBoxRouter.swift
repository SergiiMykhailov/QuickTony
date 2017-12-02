//
//  VisheoBoxRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol VisheoBoxRouter: FlowRouter {
    func showMenu()
    func showCreate()
    func show(visheo : VisheoRecord)
}

class VisheoListRouter : VisheoBoxRouter {
    enum SegueList: String, SegueListType {
        case showVisheo = "showVisheo"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: VisheoBoxViewController?
    private(set) weak var viewModel: VisheoBoxViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: VisheoBoxViewController) {
        let vm = VisheoListViewModel(visheosList: dependencies.visheosListService, creationService: dependencies.creationService)
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
        case .showVisheo:
            let shareController = segue.destination as! ShareVisheoViewController
            let shareRouter = ShareVisheoRouter(dependencies: dependencies)
            shareRouter.start(with: shareController, record: sender as! VisheoRecord)
        }
    }
}

extension VisheoListRouter {
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
    
    func showCreate() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let shownController = storyboard.instantiateViewController(withIdentifier: "ChooseOccasionViewController")
        let mainRouter = VisheoChooseOccasionRouter(dependencies: dependencies)
        mainRouter.start(with: shownController as! ChooseOccasionViewController)
        
        let navigationController = controller?.sideMenuController?.rootViewController as! UINavigationController
        navigationController.setViewControllers([shownController], animated: false)
        controller?.sideMenuController?.hideLeftView(animated: true, delay: 0.0, completionHandler: nil)
    }
    
    func show(visheo : VisheoRecord) {
        controller?.performSegue(SegueList.showVisheo, sender: visheo)
    }
}

