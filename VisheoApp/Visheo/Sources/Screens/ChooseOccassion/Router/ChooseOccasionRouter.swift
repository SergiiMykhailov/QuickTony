//
//  ChooseOccasionRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ChooseOccasionRouter: FlowRouter {
    func showSelectCover(for occasion: OccasionRecord)
    func showMenu()
}

class VisheoChooseOccasionRouter : ChooseOccasionRouter {
    enum SegueList: String, SegueListType {
        case showOccasion = "showOccasion"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: ChooseOccasionViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: ChooseOccasionViewController) {
		let vm = VisheoChooseOccasionViewModel(occasionsList: dependencies.occasionsListService,
											   appStateService: dependencies.appStateService)
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
        case .showOccasion:
            let selectCoverController = segue.destination as! SelectCoverViewController
            let selectCoverRouter = VisheoSelectCoverRouter(dependencies: dependencies, occasion: sender as! OccasionRecord)
            selectCoverRouter.start(with: selectCoverController)
        }
    }
}

extension VisheoChooseOccasionRouter {
    func showSelectCover(for occasion: OccasionRecord) {
        controller?.performSegue(SegueList.showOccasion, sender: occasion)
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
}

