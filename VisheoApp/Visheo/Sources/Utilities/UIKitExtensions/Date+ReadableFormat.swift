//
//  Date+ReadableFormat.swift
//  Visheo
//
//  Created by Ivan on 3/26/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation

extension Date {
    func visheo_readableString(withYear isYear: Bool = false) -> String {
        let formatter = DateFormatter()
        let dateFormat = isYear ? "MMMM yyyy" : "MMMM"
        formatter.dateFormat =  DateFormatter.dateFormat(fromTemplate: dateFormat, options: 0, locale: Locale.current)
        formatter.locale = Locale.current
        let dateString = String.init(format: NSLocalizedString("%1$@ of %2$@", "Readable format for date"), visheo_dayWithSuffix(), formatter.string(from: self))
        return dateString
    }
    
    private func visheo_dayWithSuffix() -> String {
        let calendar = Calendar.current
        let day = calendar.component(.day, from: self)
        
        return "\(day)\(visheo_suffix(forDay: day))"
    }
    
    private func visheo_suffix(forDay day: Int) -> String {
        switch day % 10 {
        case 1: return NSLocalizedString("st", "Suffix for *first")
        case 2: return NSLocalizedString("nd", "Suffix for *second")
        case 3: return NSLocalizedString("rd", "Suffix for *third")
        default: return NSLocalizedString("th", "Suffix for *fourth")
        }
    }
}
