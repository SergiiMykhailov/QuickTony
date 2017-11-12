//
//  OccasionCellViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol OccasionCellViewModel {
    var imageURL : URL? {get}
    var name : String {get}
}

struct VisheoOccasionCellViewModel : OccasionCellViewModel {
    let name : String
    let imageURL : URL?
}
