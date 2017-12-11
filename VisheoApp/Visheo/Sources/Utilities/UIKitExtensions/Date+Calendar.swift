//
//  Date+Calendar.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


extension Date {
    var daysFromNow : Int {
        let today = Calendar.current.startOfDay(for: Date())
        let date = Calendar.current.startOfDay(for: self)
        let components = Calendar.current.dateComponents([.day], from: today, to: date)
        return components.day ?? 0
    }
}
