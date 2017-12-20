//
//  RedeemSuccessRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


protocol RedeemSuccessRouter: FlowRouter {
    func showCreate()
	func showShareVisheo(with assets: VisheoRenderingAssets, premium: Bool)
    func showMenu()
}

class VisheoRedeemSuccessRouter : RedeemSuccessRouter {
    enum SegueList: String, SegueListType {
        case showShareVisheo = "showShareVisheo"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: RedeemSuccessViewController?
    private(set) weak var viewModel: RedeemSuccessViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
	func start(with type: RedeemSuccessType, viewController: RedeemSuccessViewController, redeemedCount: Int, assets: VisheoRenderingAssets? = nil, showBackButton: Bool) {
		let vm = VisheoRedeemSuccessViewModel(with: type,
											  count: redeemedCount,
											  assets: assets,
											  purchasesService: dependencies.premiumCardsService,
											  showBackButton: showBackButton)
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
        }
    }
}

extension VisheoRedeemSuccessRouter {
	private enum Constants {
		static let assets = "assets"
		static let premium = "premium"
	}
	
    func showCreate() {
        dependencies.routerAssembly.assembleCreateVisheoScreen(on: controller?.sideMenuController?.rootViewController as! UINavigationController, with: dependencies)
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }

	func showShareVisheo(with assets: VisheoRenderingAssets, premium: Bool) {
		controller?.performSegue(SegueList.showShareVisheo, sender: [Constants.assets : assets, Constants.premium : premium])
	}
}

