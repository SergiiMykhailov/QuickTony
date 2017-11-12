//
//  ChooseOccasionRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ChooseOccasionRouter: FlowRouter {
}

class VisheoChooseOccasionRouter : ChooseOccasionRouter {
    enum SegueList: String, SegueListType {
        case showOccasion = ""
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: ChooseOccasionViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: ChooseOccasionViewController) {
        let vm = VisheoChooseOccasionViewModel(occasionsList: dependencies.occasionsListService)
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

extension ChooseOccasionRouter {
}

