//
//  StandartOccasionsTableCellViewModel.swift
//  Visheo
//
//  Created by Ivan on 3/26/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation
import CoreGraphics

protocol StandardOccasionsTableCellViewModel {
    var title : String {get}
    var occasionsCount : Int {get}
    var selectedIndex : Int? {get}
    var subTitle : String? {get}
    
    var itemSelectionHandler : (OccasionRecord) -> () {get}
    
    func selectOccasion(at index: Int)
    func occasionViewModel(at index: Int) -> OccasionCellViewModel
}

struct VisheoStandardOccasionsTableCellViewModel : StandardOccasionsTableCellViewModel {
    static var height : CGFloat {
        let collectionViewHeight = 126 as CGFloat
        return collectionViewHeight
    }
    
    func selectOccasion(at index: Int) {
        itemSelectionHandler(occasionsList[index])
    }
    
    func occasionViewModel(at index: Int) -> OccasionCellViewModel {
        let model = occasionsList[index]
        return VisheoOccasionCellViewModel(name: model.name, imageURL: model.previewCover.previewUrl, isFree: model.isFree)
    }
    
    var title: String
    var subTitle : String?
    private var occasionsList : [OccasionRecord]
    
    var itemSelectionHandler: (OccasionRecord) -> ()
    
    init(withTitle title: String, subTitle: String?, occasions:[OccasionRecord], handler: @escaping (OccasionRecord) -> ()) {
        self.title = title
        self.subTitle = subTitle
        self.occasionsList = occasions
        self.itemSelectionHandler = handler
    }
    
    var occasionsCount: Int {
        return occasionsList.count
    }
    
    var selectedIndex: Int? {
        return 0
    }
}
