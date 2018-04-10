//
//  MenuRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol MenuRouter: FlowRouter {
    func showCreateVisheo()
    func showVisheoBox()
    func showAccount()
    func showPremiumCards()
    func showInvites()
    func showCoupons()
    func showVisheoScreen(with record: VisheoRecord)
    
	func showRegistration(with reason: AuthorizationReason)
	func showContactForm()
}

class VisheoMenuRouter : MenuRouter {
    enum SegueList: String, SegueListType {
        case showRegistration = "showRegistration"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: MenuViewController?
    private(set) weak var viewModel: MenuViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: MenuViewController) {
		let vm = VisheoMenuViewModel(userInfo: dependencies.userInfoProvider,
									 notificationService: dependencies.userNotificationsService,
									 visheoListService: dependencies.visheosListService)
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
        case .showRegistration:
            let authController = (segue.destination as! UINavigationController).viewControllers[0] as! AuthorizationViewController
            let authRouter = VisheoAuthorizationRouter(dependencies: dependencies) { _ in
                self.controller?.dismiss(animated: true, completion: nil)
            }
			authRouter.start(with: authController, anonymousAllowed: false, authReason: sender as! AuthorizationReason)
        }
    }
}

extension VisheoMenuRouter {
	func showRegistration(with reason: AuthorizationReason) {
        controller?.performSegue(SegueList.showRegistration, sender: reason)
    }
	
	func showContactForm() {
		let navigationController = controller?.sideMenuController?.rootViewController as! UINavigationController
		controller?.sideMenuController?.hideLeftView(animated: true, delay: 0.0, completionHandler: { [weak self] in
			self?.dependencies.feedbackService.showContactForm(on: navigationController);
		})
	}
    
    func showCreateVisheo() {
        showController(with: "ChooseOccasionViewController") { (controller) in
            let mainRouter = VisheoChooseOccasionRouter(dependencies: dependencies)
            mainRouter.start(with: controller as! ChooseOccasionViewController)
        }
    }
    
    func showVisheoBox() {
        showController(with: "VisheoBoxViewController") { (controller) in
            let router = VisheoListRouter(dependencies : dependencies)
            router.start(with: controller as! VisheoBoxViewController)
        }
    }
    
    func showAccount() {
        showController(with: "AccountViewController", storyboard: UIStoryboard(name: "Account", bundle: nil)) { (controller) in
            let router = VisheoAccountRouter(dependencies: dependencies)
            router.start(with: controller as! AccountViewController)
        }
    }

	func showVisheoScreen(with record: VisheoRecord) {
		let storyboard = UIStoryboard(name: "VisheoPreview", bundle: nil)
		
		pushController(with: "ShareVisheoViewController", storyboard: storyboard) { (controller) in
			let router = ShareVisheoRouter(dependencies: dependencies);
			router.start(with: controller as! ShareVisheoViewController, record: record);
		}
	}
    
    func showPremiumCards() {
        showController(with: "ChooseCardsViewController", storyboard: UIStoryboard(name: "Purchases", bundle: nil)) { (controller) in
            let router = VisheoChooseCardsRouter(dependencies: dependencies)
            router.start(with: controller as! ChooseCardsViewController, fromMenu: true)
        }
    }
    
    func showCoupons() {
        showController(with: "RedeemViewController", storyboard: UIStoryboard(name: "Purchases", bundle: nil)) { (controller) in
            let router = VisheoRedeemRouter(dependencies: dependencies)
            router.start(with: controller as! RedeemViewController, assets: nil, showBack: false)
        }
    }
    
    func showInvites() {
        showController(with: "InviteFriendsViewController", storyboard: UIStoryboard(name: "Main", bundle: nil)) { (controller) in
            let router = VisheoInviteFriendsRouter(dependencies: dependencies)
            router.start(controller: controller as! InviteFriendsViewController)
        }
    }
    
    private func showController(with id: String, storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil), setup: (UIViewController) -> ()) {
        let shownController = storyboard.instantiateViewController(withIdentifier: id)
        setup(shownController)        
        let navigationController = controller?.sideMenuController?.rootViewController as! UINavigationController
        navigationController.setViewControllers([shownController], animated: false)
        controller?.sideMenuController?.hideLeftView(animated: true, delay: 0.0, completionHandler: nil)
    }
	
	private func pushController(with id: String, storyboard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil), setup: (UIViewController) -> ()) {
		let shownController = storyboard.instantiateViewController(withIdentifier: id)
		setup(shownController)
		let navigationController = controller?.sideMenuController?.rootViewController as! UINavigationController
		navigationController.show(shownController, sender: nil);
		controller?.sideMenuController?.hideLeftView(animated: true, delay: 0.0, completionHandler: nil)
	}
}

