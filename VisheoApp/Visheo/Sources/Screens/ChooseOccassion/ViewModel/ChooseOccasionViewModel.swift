//
//  ChooseOccasionViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase

protocol ChooseOccasionViewModel : class {
    var occasionGroupsCount : Int {get}
    var occasionGroups : [OccasionGroup] {get}
    func selectOccasion(withOccasion occasion: OccasionRecord)
    
    var didChangeCallback: (()->())? {get set}
    
    func showMenu()
	func showReviewChoiceIfNeeded()
}

class VisheoChooseOccasionViewModel : ChooseOccasionViewModel {

    var didChangeCallback: (() -> ())? {
        didSet {
            didChangeCallback?()
        }
    }
    
    var occasionGroupsCount: Int {
        return occasionGroupsList.occasionGroups.count
    }
    
    var occasionGroups: [OccasionGroup] {
        return occasionGroupsList.occasionGroups
    }
    
    weak var router: ChooseOccasionRouter?
    var occasionsList : OccasionsListService
    var occasionGroupsList : OccasionGroupsListService
	private let appStateService: AppStateService;
	private let feedbackService: FeedbackService
	private let isInitialLaunch: Bool;
    
	init(isInitialLaunch: Bool, occasionsList: OccasionsListService, occasionGroupsList: OccasionGroupsListService, appStateService: AppStateService, feedbackService: FeedbackService) {
		self.isInitialLaunch = isInitialLaunch
        self.occasionsList = occasionsList
        self.occasionGroupsList = occasionGroupsList
		self.appStateService = appStateService
		self.feedbackService = feedbackService
        
        NotificationCenter.default.addObserver(forName: Notification.Name.occasionGroupsChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.didChangeCallback?()
        }
		
		NotificationCenter.default.addObserver(forName: .reachabilityChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
			if let reachable = self?.appStateService.isReachable, reachable {
				self?.didChangeCallback?();
			}
		}
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func showMenu() {
        router?.showMenu()
    }
	
    func selectOccasion(withOccasion occasion: OccasionRecord) {
        if appStateService.shouldShowOnboardingCover {
            router?.showCoverOnboarding(for: occasion)
        } else {
            router?.showSelectCover(for: occasion)
        }
    }
    
	func showReviewChoiceIfNeeded() {
		guard isInitialLaunch else {
			return;
		}
		feedbackService.isReviewPending { [weak self] (isPending) in
			if (isPending) {
				self?.router?.showReviewChoice();
			}
		}
	}
}
