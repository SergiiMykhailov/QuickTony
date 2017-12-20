//
//  ChooseCardsRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ChooseCardsRouter: FlowRouter {
    func showMenu()
    func showShareVisheo(with assets: VisheoRenderingAssets, premium: Bool)
    func showCreateVisheo()
    func showCoupon(with assets: VisheoRenderingAssets?)
	func showPurchaseSuccess(with count: Int, assets: VisheoRenderingAssets?);
}

class VisheoChooseCardsRouter : ChooseCardsRouter {
    enum SegueList: String, SegueListType {
        case showShareVisheo = "showShareVisheo"
        case showCoupon = "showCoupon"
		case showPurchaseSuccess = "showPurchaseSuccess"
    }
	
    let dependencies: RouterDependencies
    private(set) weak var controller: ChooseCardsViewController?
    private(set) weak var viewModel: ChooseCardsViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: ChooseCardsViewController, fromMenu: Bool, with assets: VisheoRenderingAssets? = nil) {
        let vm = VisheoChooseCardsViewModel(fromMenu: fromMenu, purchasesService: dependencies.premiumCardsService, purchasesInfo: dependencies.purchasesInfo, assets: assets)
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
        case .showShareVisheo:
            let sendController = segue.destination as! ShareVisheoViewController
            let sendRouter = ShareVisheoRouter(dependencies: dependencies)
            let userInfo = sender as! [String : Any]
            sendRouter.start(with: sendController,
                             assets: userInfo[Constants.assets] as! VisheoRenderingAssets,
                             sharePremium : userInfo[Constants.premium] as! Bool)
        case .showCoupon:
            let couponController = segue.destination as! RedeemViewController
            let router = VisheoRedeemRouter(dependencies: dependencies)
            let assets = sender as? VisheoRenderingAssets
            router.start(with: couponController, assets: assets, showBack: assets != nil)
		case .showPurchaseSuccess:
			let successController = segue.destination as! RedeemSuccessViewController
			let router = VisheoRedeemSuccessRouter(dependencies: dependencies)
			let userInfo = sender as! [String : Any]
			let assets = userInfo[Constants.assets] as? VisheoRenderingAssets
			router.start(with: .inAppPurchase,
						 viewController: successController,
						 redeemedCount: userInfo[Constants.count] as! Int,
						 assets: assets,
						 showBackButton: assets != nil)
        }
    }
}

extension VisheoChooseCardsRouter {
    private enum Constants {
        static let assets = "assets"
        static let premium = "premium"
		static let count = "count"
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
    
    func showShareVisheo(with assets: VisheoRenderingAssets, premium: Bool) {
        controller?.performSegue(SegueList.showShareVisheo, sender: [Constants.assets : assets, Constants.premium : premium])
    }
	
    func showCreateVisheo() {
        dependencies.routerAssembly.assembleCreateVisheoScreen(on: controller?.sideMenuController?.rootViewController as! UINavigationController, with: dependencies)
    }
    
    func showCoupon(with assets: VisheoRenderingAssets?) {
        controller?.performSegue(SegueList.showCoupon, sender: assets)
    }
	
	func showPurchaseSuccess(with count: Int, assets: VisheoRenderingAssets?) {
		controller?.performSegue(SegueList.showPurchaseSuccess, sender: [ Constants.count : count, Constants.assets: assets as Any ])
	}
}

