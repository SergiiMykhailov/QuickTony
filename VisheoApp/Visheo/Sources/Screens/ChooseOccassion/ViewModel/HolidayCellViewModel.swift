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
    var isFree: Bool {get}
}

struct VisheoHolidayCellViewModel : HolidayCellViewModel {
    let date : Date?
    let imageURL : URL?
    let isFree: Bool
    
	var displaysDate: Bool {
		return false;
//		return !holidayDateText.isEmpty;
	}
	
    var holidayDateText : String {
        guard let date = date else { return ""}
        return date.readableString()
    }
}
