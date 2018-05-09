//
//  PremiumCellViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/27/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation

protocol PremiumCellViewModel {
    var imageURL : URL? {get}
    var isFree: Bool {get}
}

struct VisheoPremiumCellViewModel : PremiumCellViewModel {
    let imageURL : URL?
    let isFree: Bool
}
