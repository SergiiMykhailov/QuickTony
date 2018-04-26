//
//  SubscriptionDescriptionRouter.swift
//  Visheo
//
//  Created by Ivan on 4/18/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol SubscriptionDescriptionRouter: FlowRouter {
    func showPurchaseSuccess()
}

class DefaultSubscriptionDescriptionRouter:  SubscriptionDescriptionRouter {
    
    var dependencies: RouterDependencies
    
    var assets: VisheoRenderingAssets?
    
    enum SegueList: String, SegueListType {
        case showPurchaseSuccess = "showPurchaseSuccess"
    }

    private(set) weak var viewModel: SubscriptionDescriptionViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let segueList = SegueList(segue: segue) else {
            return
        }

        switch segueList {
            case .showPurchaseSuccess:
                let successController = segue.destination as! RedeemSuccessViewController
                let router = VisheoRedeemSuccessRouter(dependencies: dependencies)
                router.start(with: .inAppPurchase,
                             viewController: successController,
                             redeemedCount: 0,
                             assets: assets,
                             showBackButton: assets != nil)
                break
            }
    }

    init(withDependencies dependencies: RouterDependencies, assets: VisheoRenderingAssets?) {
        self.dependencies = dependencies
        self.assets = assets
    }

    func start(controller: SubscriptionDescriptionViewController) {
        self.controller = controller
        let vm = SubscriptionDescriptionControllerViewModel(router: self, delegate: controller, purchasesService: dependencies.premiumCardsService)
        viewModel = vm
        controller.configure(viewModel: vm, router: self)
    }
}

extension DefaultSubscriptionDescriptionRouter {
    
    func showPurchaseSuccess() {
        controller?.performSegue(SegueList.showPurchaseSuccess, sender: assets)
    }
}
