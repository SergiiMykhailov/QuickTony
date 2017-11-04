//
//  SignUpRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SignUpRouter: FlowRouter {
}

class VisheoSignUpRouter : SignUpRouter {
    enum SegueList: String, SegueListType {
        case showMainScreen = "showMainScreen"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: SignUpViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: SignUpViewController) {
        let vm = VisheoSignUpViewModel()
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

extension VisheoSignUpRouter {
}

