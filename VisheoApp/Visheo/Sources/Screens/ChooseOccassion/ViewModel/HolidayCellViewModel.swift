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
	var displaysDate: Bool { get }
    var holidayDateText : String {get}
}

struct VisheoHolidayCellViewModel : HolidayCellViewModel {
    let date : Date?
    let imageURL : URL?
	
	var displaysDate: Bool {
		return false;
//		return !holidayDateText.isEmpty;
	}
	
    var holidayDateText : String {
        guard let date = date else { return ""}
        return date.visheo_readableString()
    }
}

extension Date {
    func visheo_readableString(withYear isYear: Bool = false) -> String {
        let formatter = DateFormatter()
        let dateFormat = isYear ? "MMMM yyyy" : "MMMM"
        formatter.dateFormat =  DateFormatter.dateFormat(fromTemplate: dateFormat, options: 0, locale: Locale.current)
        formatter.locale = Locale.current
        let dateString = String.init(format: "%1$@ of %2$@", visheo_dayWithSuffix(), formatter.string(from: self))
        return dateString
    }
    
    private func visheo_dayWithSuffix() -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        
        return "\(day)\(visheo_suffix(forDay: day))"
    }
    
    private func visheo_suffix(forDay day: Int) -> String {
        switch day % 10 {
        case 1: return "st"
        case 2: return "nd"
        case 3: return "rd"
        default: return "th"
        }
    }
}
