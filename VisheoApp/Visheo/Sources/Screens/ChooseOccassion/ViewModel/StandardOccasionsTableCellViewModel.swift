//
//  StandartOccasionsTableCellViewModel.swift
//  Visheo
//
//  Created by Ivan on 3/26/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation

protocol StandardOccasionsTableCellViewModel {
    var title : String {get}
    var occasionsCount : Int {get}
    var selectedIndex : Int? {get}
    
    var itemSelectionHandler : (OccasionRecord) -> () {get}
    
    func selectOccasion(at index: Int)
    func occasionViewModel(at index: Int) -> OccasionCellViewModel
}

struct VisheoStandardOccasionsTableCellViewModel : StandardOccasionsTableCellViewModel {
    func selectOccasion(at index: Int) {
        itemSelectionHandler(occasionsList[index])
    }
    
    func occasionViewModel(at index: Int) -> OccasionCellViewModel {
        let model = occasionsList[index]
        return VisheoOccasionCellViewModel.init(name: model.name, imageURL: model.previewCover.previewUrl)
    }
    
    var title: String
    private var occasionsList : [OccasionRecord]
    
    var itemSelectionHandler: (OccasionRecord) -> ()
    
    init(withTitle title: String, occasions:[OccasionRecord], handler: @escaping (OccasionRecord) -> ()) {
        self.title = title
        self.occasionsList = occasions.sorted {
            $0.priority > $1.priority
        }
        self.itemSelectionHandler = handler
    }
    
    var occasionsCount: Int {
        return occasionsList.count
    }
    
    var selectedIndex: Int? {
        return 0
    }
}
