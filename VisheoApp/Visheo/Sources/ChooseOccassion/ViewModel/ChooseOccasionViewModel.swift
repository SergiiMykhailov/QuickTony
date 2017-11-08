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
    
    func holidayViewModel(at index: Int) -> HolidayCellViewModel
    func occasionViewModel(at index: Int) -> OccasionCellViewModel
    
    var didChangeCallback: (()->())? {get set}
}

class VisheoChooseOccasionViewModel : ChooseOccasionViewModel {
    var didChangeCallback: (() -> ())?
    
    func holidayViewModel(at index: Int) -> HolidayCellViewModel {
        let record = holidays[index]
        return VisheoHolidayCellViewModel(date: record.date, imageURL: record.previewCoverUrl)
    }
    
    func occasionViewModel(at index: Int) -> OccasionCellViewModel {
        let record = occasions[index]
        return VisheoOccasionCellViewModel(name: record.name, imageURL: record.previewCoverUrl)
    }
    
    var holidaysCount: Int {
        return holidays.count
    }
    
    var occasionsCount: Int {
        return occasions.count
    }
    
    weak var router: ChooseOccasionRouter?
    var occasionsList : OccasionsListService
    
    init(occasionsList: OccasionsListService) {
        self.occasionsList = occasionsList
        self.occasionsList.didChangeRecords = {[weak self] in
            self?.didChangeCallback?()
        }
    }
    
    private var holidays : [OccasionRecord] {
        return self.occasionsList.occasionsRecords().filter {
            $0.category == OccasionCategory.holiday
            }.sorted {
                let date0 = $0.date ?? Date.distantFuture
                let date1 = $1.date ?? Date.distantFuture
                return date0.compare(date1) == .orderedAscending
                }
    }
    
    private var occasions : [OccasionRecord] {
        return self.occasionsList.occasionsRecords().filter {
            $0.category == OccasionCategory.occasion
            }.sorted {
                $0.priority < $1.priority
        }
    }
}
