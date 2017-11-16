//
//  SelectCoverRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SelectCoverRouter: FlowRouter {
}

class VisheoSelectCoverRouter : SelectCoverRouter {
    enum SegueList: String, SegueListType {
        case next //TODO: Add correct
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: SelectCoverViewModel?
    
    let occasion : OccasionRecord
    
    public init(dependencies: RouterDependencies, occasion: OccasionRecord) {
        self.dependencies = dependencies
        self.occasion = occasion
    }
    
    func start(with viewController: SelectCoverViewController) {
        let vm = VisheoSelectCoverViewModel(occasion: self.occasion)
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

extension SelectCoverRouter {
}

