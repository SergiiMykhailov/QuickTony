//
//  ShareVisheoViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol ShareViewModel : class {
}

class ShareVisheoViewModel : ShareViewModel {
    weak var router: ShareRouter?
    
    init() {
    }
}
