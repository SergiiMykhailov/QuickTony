//
//  ShareVisheoOnboardingRouter.swift
//  Visheo
//
//  Created by Ivan on 3/29/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol ShareOnboardingRouter: FlowRouter {
    func showShareVisheo()
}

class VisheoShareOnboardingRouter: ShareOnboardingRouter {
    private(set) var dependencies: RouterDependencies
    private(set) var assets: VisheoRenderingAssets
    private(set) var premium: Bool
    
    enum SegueList: String, SegueListType {
        case showSendVisheo = "showSendVisheo"
    }

    private(set) weak var viewModel: ShareVisheoOnboardingViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let segueList = SegueList(segue: segue) else {
            return
        }

        switch segueList {
        case .showSendVisheo:
            let sendController = segue.destination as! ShareVisheoViewController
            let sendRouter = ShareVisheoRouter(dependencies: dependencies)
            sendRouter.start(with: sendController,
                             assets: assets,
                             sharePremium: premium)
        }
    }

    init(dependencies: RouterDependencies, assets: VisheoRenderingAssets, premium: Bool) {
        self.dependencies = dependencies
        self.assets = assets
        self.premium = premium
    }

    func showShareVisheo() {
        controller?.performSegue(SegueList.showSendVisheo, sender: assets)
    }
    
    func start(with controller: ShareVisheoOnboardingViewController) {
        self.controller = controller
        let vm = ShareVisheoOnboardingControllerViewModel(appStateService: dependencies.appStateService, router: self)
        viewModel = vm
        controller.configure(viewModel: vm, router: self)
    }
}
