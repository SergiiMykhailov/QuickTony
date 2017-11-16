//
//  SelectCoverViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import SDWebImage

extension Notification.Name {
    static let preselectedCoverChanged = Notification.Name("preselectedCoverChanged")
}

protocol SelectCoverViewModel : LongFailableActionViewModel {
    func coverViewModel(at index: Int) -> CoverCellViewModel
    var coversNumber : Int {get}
    
    var preselectedCoverIndex : Int {get set}
    
    func selectCover()
}

class VisheoSelectCoverViewModel : SelectCoverViewModel {
    var showProgressCallback: ((Bool) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var preselectedCoverIndex: Int {
        didSet {
            NotificationCenter.default.post(name: .preselectedCoverChanged, object: self)
        }
    }
    
    weak var router: SelectCoverRouter?
    let occasion : OccasionRecord
    
    init(occasion: OccasionRecord) {
        self.occasion = occasion
        preselectedCoverIndex = 0
    }
    
    func coverViewModel(at index: Int) -> CoverCellViewModel {
        return VisheoCoverCellViewModel(imageURL: occasion.covers[index].previewUrl)
    }
    
    var coversNumber: Int {
        return occasion.covers.count
    }
    
    func selectCover() {
        showProgressCallback?(true)
        let selectedCover = occasion.covers[preselectedCoverIndex]
        
        SDWebImageManager.shared().loadImage(with: selectedCover.url, options: [], progress: nil) { (image, data, error, cacheType, success, url) in
            self.showProgressCallback?(false)
            if (image != nil) {
//                Save file
                //TODO: NAvigate further
            } else if let error = error {
                self.warningAlertHandler?(error.localizedDescription)
            }
        }
    }
}
