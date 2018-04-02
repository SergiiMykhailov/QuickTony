//
//  EditVideoDescriptionRouter.swift
//  Visheo
//
//  Created by Ivan on 4/2/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol EditVideoDescriptionRouter: FlowRouter {
    
}

class DefaultEditVideoDescriptionRouter:  EditVideoDescriptionRouter {
    enum SegueList: String, SegueListType {
        case next
    }

    let dependencies: RouterDependencies
    
    private(set) weak var viewModel: EditVideoDescriptionViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for orgSegue: UIStoryboardSegue, sender: Any?) {

        guard let segue = SegueList(segue: orgSegue) else {
            return
        }

        switch segue {
        default:
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(with description: String,
               editHandler: ((String) -> ())?,
               controller: EditVideoDescriptionViewController) {
        self.controller = controller
        let vm = EditVideoDescriptionControllerViewModel(router: self, description: description, editSuccessHandler: editHandler)
        viewModel = vm
        controller.configure(viewModel: vm, router: self)
    }
}
