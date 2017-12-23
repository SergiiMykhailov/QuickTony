//
//  ChooseOccasionViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

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
}

class VisheoChooseOccasionViewModel : ChooseOccasionViewModel {
    
    private let maxPastDays = 2
    var firstFutureHolidayIndex: Int? {
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
    
	init(occasionsList: OccasionsListService, appStateService: AppStateService) {
        self.occasionsList = occasionsList
		self.appStateService = appStateService;
        
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
            $0.category == OccasionCategory.holiday
            }.sorted {
                let date0 = $0.date ?? Date.distantFuture
                let date1 = $1.date ?? Date.distantFuture
                return date0.compare(date1) == .orderedAscending
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
}


