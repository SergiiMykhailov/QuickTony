//
//  HolidayCellViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol HolidayCellViewModel {
    var imageURL : URL? {get}
    var holidayDateText : String {get}
}

struct VisheoHolidayCellViewModel : HolidayCellViewModel {
    let date : Date?
    let imageURL : URL?
    
    var holidayDateText : String {
        guard let date = date else { return ""}
        let formatter = DateFormatter()
        formatter.dateFormat =  DateFormatter.dateFormat(fromTemplate: "dMMMM", options: 0, locale: Locale.current)
        formatter.locale = Locale.current
        return formatter.string(from: date)
    }
}
