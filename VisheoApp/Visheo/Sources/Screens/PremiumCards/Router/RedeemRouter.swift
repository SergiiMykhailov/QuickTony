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
    func showSuccess(with cardCount: Int, assets: VisheoRenderingAssets?)
}

class VisheoRedeemRouter : RedeemRouter {
    enum SegueList: String, SegueListType {
        case showSuccess = "showRedeemSuccess"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: RedeemViewController?
    private(set) weak var viewModel: RedeemViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: RedeemViewController, assets: VisheoRenderingAssets?, showBack: Bool) {
		let vm = VisheoRedeemViewModel(purchasesService: dependencies.premiumCardsService,
									   appStateService: dependencies.appStateService,
									   loggingService: dependencies.loggingService, showBack: showBack, assets: assets)
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
			let userInfo = sender as! [String : Any]
			let assets = userInfo[Constants.assets] as? VisheoRenderingAssets
			router.start(with: .couponRedeem,
						 viewController: successController,
						 redeemedCount: userInfo[Constants.count] as! Int,
						 assets: assets,
						 showBackButton: assets != nil)
        }
    }
}

extension VisheoRedeemRouter {
    private enum Constants {
        static let assets = "assets"
        static let premium = "premium"
		static let count = "count"
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
    
	func showSuccess(with cardCount: Int, assets: VisheoRenderingAssets?) {
        controller?.performSegue(SegueList.showSuccess, sender: [Constants.assets : assets as Any,
																 Constants.count : cardCount])
    }
}



