//
//  ChooseOccasionRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol ChooseOccasionRouter: FlowRouter {
    func showSelectCover(for occasion: OccasionRecord)
    func showCoverOnboarding(for occasion: OccasionRecord)
    func showMenu()
	func showReviewChoice()
}

class VisheoChooseOccasionRouter : ChooseOccasionRouter {
    enum SegueList: String, SegueListType {
        case showOccasion = "showOccasion"
        case showCoverOnboarding = "showCoverOnboarding"
    }
    let dependencies: RouterDependencies
	private let isInitialLaunch: Bool;
    private(set) weak var controller: UIViewController?
    private(set) weak var viewModel: ChooseOccasionViewModel?
    
	public init(dependencies: RouterDependencies, isInitialLaunch: Bool = false) {
        self.dependencies = dependencies
		self.isInitialLaunch = isInitialLaunch;
    }
    
    func start(with viewController: ChooseOccasionViewController) {
		let vm = VisheoChooseOccasionViewModel(isInitialLaunch: isInitialLaunch,
											   occasionsList: dependencies.occasionsListService,
                                               occasionGroupsList: dependencies.occasionGroupsListService,
											   appStateService: dependencies.appStateService,
											   feedbackService: dependencies.feedbackService)
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
        case .showOccasion:
            let selectCoverController = segue.destination as! SelectCoverViewController
            let selectCoverRouter = VisheoSelectCoverRouter(dependencies: dependencies, occasion: sender as! OccasionRecord)
            selectCoverRouter.start(with: selectCoverController)
        case .showCoverOnboarding:
            let coverOnBoardingVC = segue.destination as! CoverOnboardingScreenViewController
            let permissionsRouter = VisheoCoverOnboardingScreenRouter(dependencies: dependencies, occasion: sender as! OccasionRecord)
            permissionsRouter.start(with: coverOnBoardingVC)
        }
    }
}

extension VisheoChooseOccasionRouter {
    func showSelectCover(for occasion: OccasionRecord) {
        controller?.performSegue(SegueList.showOccasion, sender: occasion)
    }
    
    func showCoverOnboarding(for occasion: OccasionRecord) {
        controller?.performSegue(SegueList.showCoverOnboarding, sender: occasion)
    }
    
    func showMenu() {
        controller?.showLeftViewAnimated(self)
    }
	
	func showReviewChoice() {
		if let navigation = controller?.navigationController {
			dependencies.feedbackService.showReviewChoice(on: navigation, onCancel: nil);
		}
	}
}

