//
//  RedeemRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol RedeemRouter: FlowRouter {
    func showMenu()
    func showSuccess(with cardCount: Int)
    func showShareVisheo(with assets: VisheoRenderingAssets, premium: Bool)
}

class VisheoRedeemRouter : RedeemRouter {
    enum SegueList: String, SegueListType {
        case showSuccess = "showSuccess"
        case showShareVisheo = "showShareVisheo"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: RedeemViewController?
    private(set) weak var viewModel: RedeemViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: RedeemViewController, assets: VisheoRenderingAssets?, showBack: Bool) {
		let vm = VisheoRedeemViewModel(purchasesService: dependencies.premiumCardsService, appStateService: dependencies.appStateService, showBack: showBack, assets: assets)
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
        case .showSuccess:
            let successController = segue.destination as! RedeemSuccessViewController
            let router = VisheoRedeemSuccessRouter(dependencies: dependencies)
            router.start(with: successController, redeemedCount: sender as! Int)
        case .showShareVisheo:
            let sendController = segue.destination as! ShareVisheoViewController
            let sendRouter = ShareVisheoRouter(dependencies: dependencies)
            let userInfo = sender as! [String : Any]
            sendRouter.start(with: sendController,
                             assets: userInfo[Constants.assets] as! VisheoRenderingAssets,
                             sharePremium : userInfo[Constants.premium] as! Bool)
        }
    }
}

extension VisheoRedeemRouter {
    private enum Constants {
        static let assets = "assets"
        static let premium = "premium"
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
    
    func showSuccess(with cardCount: Int) {
        controller?.performSegue(SegueList.showSuccess, sender: cardCount)
    }
    
    func showShareVisheo(with assets: VisheoRenderingAssets, premium: Bool) {
        controller?.performSegue(SegueList.showShareVisheo, sender: [Constants.assets : assets, Constants.premium : premium])
    }
}



