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
    var holidaysCount : Int {get}
    var occasionsCount : Int {get}
    var firstFutureHolidayIndex : Int? {get}
    
    func holidayViewModel(at index: Int) -> HolidayCellViewModel
    func occasionViewModel(at index: Int) -> OccasionCellViewModel
    
    func selectHoliday(at index: Int)
    func selectOccasion(at index: Int)
    
    var didChangeCallback: (()->())? {get set}
    
    func showMenu()
	func showReviewChoiceIfNeeded()
}

class VisheoChooseOccasionViewModel : ChooseOccasionViewModel {
    
    private let maxPastDays = 2
    var firstFutureHolidayIndex: Int? {
		if let idx = holidays.index(where: { $0.category == .featured }) {
			return idx;
		}
        return holidays.index { ($0.date?.daysFromNow ?? 0) >= -maxPastDays }
    }
    
    var didChangeCallback: (() -> ())? {
        didSet {
            didChangeCallback?()
        }
    }
    
    func holidayViewModel(at index: Int) -> HolidayCellViewModel {
        let record = holidays[index]
        return VisheoHolidayCellViewModel(date: record.date, imageURL: record.previewCover.previewUrl)
    }
    
    func occasionViewModel(at index: Int) -> OccasionCellViewModel {
        let record = occasions[index]
        return VisheoOccasionCellViewModel(name: record.name, imageURL: record.previewCover.previewUrl)
    }
    
    var holidaysCount: Int {
        return holidays.count
    }
    
    var occasionsCount: Int {
        return occasions.count
    }
    
    weak var router: ChooseOccasionRouter?
    var occasionsList : OccasionsListService
	private let appStateService: AppStateService;
	private let feedbackService: FeedbackService
	private let isInitialLaunch: Bool;
    
	init(isInitialLaunch: Bool, occasionsList: OccasionsListService, appStateService: AppStateService, feedbackService: FeedbackService) {
		self.isInitialLaunch = isInitialLaunch;
		self.occasionsList = occasionsList
		self.appStateService = appStateService;
		self.feedbackService = feedbackService;
        
        NotificationCenter.default.addObserver(forName: Notification.Name.occasionsChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
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
    
    private var holidays : [OccasionRecord] {
        return self.occasionsList.occasionRecords.filter {
            $0.category == .holiday || $0.category == .featured
            }.sorted { (lhs, rhs) in
				switch (lhs.category, rhs.category) {
					case (.featured, .featured):
						return lhs.priority < rhs.priority;
					case (.featured, .holiday):
						let date0 = Date()
						let date1 = rhs.date ?? Date.distantFuture
						return date0.compare(date1) == .orderedAscending
					case (.holiday, .featured):
						let date0 = lhs.date ?? Date.distantFuture
						let date1 = Date()
						return date0.compare(date1) == .orderedAscending
					default:
						let date0 = lhs.date ?? Date.distantFuture
						let date1 = rhs.date ?? Date.distantFuture
						return date0.compare(date1) == .orderedAscending
				}
			}
    }
    
    private var occasions : [OccasionRecord] {
        return self.occasionsList.occasionRecords.filter {
            $0.category == OccasionCategory.occasion
            }.sorted {
                $0.priority < $1.priority
        }
    }
    
    func selectHoliday(at index: Int) {
        self.router?.showSelectCover(for: holidays[index])
    }
    
    func selectOccasion(at index: Int) {
        self.router?.showSelectCover(for: occasions[index])
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


