//
//  FeaturedOccasionsTableCellViewModel.swift
//  Visheo
//
//  Created by Ivan on 3/26/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation

protocol FeaturedOccasionsTableCellViewModel {
    var title : String {get}
    var subTitle : String? {get}
    var occasionsCount : Int {get}
    var firstSelectedIndex : Int? {get}
    
    var itemSelectionHandler : (OccasionRecord) -> () {get}
    
    func selectOccasion(at index: Int)
    func occasionViewModel(at index: Int) -> HolidayCellViewModel
}

struct VisheoFeaturedOccasionsTableCellViewModel : FeaturedOccasionsTableCellViewModel {
    var title : String
    var subTitle : String?
    private var occasionsList : [OccasionRecord]
    var itemSelectionHandler : (OccasionRecord) -> ()
    
    var occasionsCount: Int {
        return occasionsList.count
    }
    
    init(withTitle title: String,
                subTitle: String?,
               occasions: [OccasionRecord],
                 handler: @escaping (OccasionRecord) -> ()) {
        self.title = title
        self.subTitle = subTitle
        self.occasionsList = occasions.sorted { (lhs, rhs) in
            switch (lhs.category, rhs.category) {
                case (.featured, .featured):
                    return lhs.priority < rhs.priority;
                default:
                    let date0 = (lhs.category == .featured) ? Date() : lhs.date ?? Date.distantFuture
                    let date1 = (rhs.category == .featured) ? Date() : lhs.date ?? Date.distantFuture
                    return date0.compare(date1) == .orderedAscending
            }
        }
        self.itemSelectionHandler = handler
    }
    
    private let maxPastDays = 2
    var firstSelectedIndex: Int? {
        if let idx = occasionsList.index(where: { $0.category == .featured }) {
            return idx;
        }
        return occasionsList.index { ($0.date?.daysFromNow ?? 0) >= -maxPastDays }
    }
    
    func selectOccasion(at index: Int) {
        itemSelectionHandler(occasionsList[index])
    }
    
    func occasionViewModel(at index: Int) -> HolidayCellViewModel {
        let model = occasionsList[index]
        return VisheoHolidayCellViewModel(date: model.date, imageURL: model.previewCover.previewUrl)
    }
}
