//
//  ShareVisheoRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ShareRouter: FlowRouter {
    func goToRoot()
    func showMenu()
	func showReviewChoice(onCancel: (() -> Void)?)
    func showEditDescriptionScreen(withDescription description: String, successEditinHandle: @escaping (String) -> ())
}

class ShareVisheoRouter : ShareRouter {
    private enum Constants {
        static let description = "description"
        static let successEditinHandle = "successEditinHandle"
    }
    
    enum SegueList: String, SegueListType {
        case showEditDescription = "showEditDescription"
    }
    
    let dependencies: RouterDependencies
    private(set) weak var controller: ShareVisheoViewController?
    private(set) weak var viewModel: ShareViewModel?
    
    public init(dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }
    
    func start(with viewController: ShareVisheoViewController, assets: VisheoRenderingAssets, sharePremium: Bool) {
		let vm = ShareVisheoViewModel(assets: assets,
									  renderingService: dependencies.renderingService,
									  creationService: dependencies.creationService,
                                      notificationsService: dependencies.userNotificationsService,
									  loggingService: dependencies.loggingService,
									  userInfo: dependencies.userInfoProvider,
									  feedbackService: dependencies.feedbackService,
                                      sharePremium : sharePremium,
                                      appStateService: dependencies.appStateService,
                                      permissionsService: dependencies.appPermissionsService)
        viewModel = vm
        vm.router = self
        self.controller = viewController
        viewController.configure(viewModel: vm, router: self)        
        vm.startRendering()
    }
	
	func start(with viewController: ShareVisheoViewController, incompleteRecord record: VisheoRecord) {
		let vm = ShareVisheoViewModel(record: record,
									  renderingService: dependencies.renderingService,
									  creationService: dependencies.creationService,
									  notificationsService: dependencies.userNotificationsService,
									  loggingService: dependencies.loggingService,
									  userInfo: dependencies.userInfoProvider,
                                      feedbackService: dependencies.feedbackService,
                                      appStateService: dependencies.appStateService,
                                      permissionsService: dependencies.appPermissionsService)
		viewModel = vm
		vm.router = self
		self.controller = viewController
		viewController.configure(viewModel: vm, router: self)
	}
    
    func start(with viewController: ShareVisheoViewController, record: VisheoRecord) {
		guard !dependencies.creationService.isIncomplete(visheoId: record.id) else {
			start(with: viewController, incompleteRecord: record);
			return;
		}
		
		let vm = ExistingVisheoShareViewModel(record: record,
											  visheoService: dependencies.creationService,
											  cache: dependencies.visheosCache,
											  notificationsService: dependencies.userNotificationsService,
											  loggingService: dependencies.loggingService,
											  userInfo: dependencies.userInfoProvider,
                                              feedbackService: dependencies.feedbackService,
                                              appStateService: dependencies.appStateService,
                                              permissionsService: dependencies.appPermissionsService)
		
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
            case .showEditDescription:
                let editController = segue.destination as! EditVideoDescriptionViewController
                let editRouter = DefaultEditVideoDescriptionRouter(dependencies: dependencies)
                let userInfo = sender as! [String : Any]
                let description = userInfo[Constants.description] as? String
                let successEditHandler = userInfo[Constants.successEditinHandle] as? (String) -> ()
                editRouter.start(with: description!,
                                 editHandler: successEditHandler,
                                 controller: editController)
        }
    }
}

extension ShareVisheoRouter {
    func goToRoot() {
        controller?.navigationController?.popToRootViewController(animated: true)
    }
    
    func showMenu() {
         controller?.showLeftViewAnimated(self)
    }
	
	func showReviewChoice(onCancel: (() -> Void)?) {
		if let navigation = controller?.navigationController {
			dependencies.feedbackService.showReviewChoice(on: navigation, onCancel: onCancel);
		}
	}
    
    func showEditDescriptionScreen(withDescription description: String, successEditinHandle: @escaping (String) -> ()) {
        controller?.performSegue(SegueList.showEditDescription, sender: [Constants.description : description, Constants.successEditinHandle : successEditinHandle])
    }
}

