//
//  InviteFriendsRouter.swift
//  Visheo
//
//  Created by Ivan on 4/10/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol InviteFriendsRouter: FlowRouter {
    func showMenu()
}

class VisheoInviteFriendsRouter:  InviteFriendsRouter {
    var dependencies: RouterDependencies
    
    enum SegueList: String, SegueListType {
        case placeholder = "#Placeholder#"
    }

    private(set) weak var viewModel: InviteFriendsViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for orgSegue: UIStoryboardSegue, sender: Any?) {

        guard let segue = SegueList(segue: orgSegue) else {
            return
        }

        switch segue {
        case .placeholder:
            break
        }
    }

    init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(controller: InviteFriendsViewController) {
        self.controller = controller
        let vm = InviteFriendsControllerViewModel(router: self, loggingService: dependencies.loggingService, invitationService: dependencies.invitationService)
        viewModel = vm
        vm.delegate = controller
        controller.configure(viewModel: vm, router: self)
    }
    
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
}
