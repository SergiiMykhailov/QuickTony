//
//  CoverCellViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol CoverCellViewModel {
    var imageURL : URL? {get}
}

struct VisheoCoverCellViewModel : CoverCellViewModel {
    let imageURL: URL?
}

