//
//  PhotoPickerViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol PhotoPickerViewModel : class {
}

class VisheoPhotoPickerViewModel : PhotoPickerViewModel {
    weak var router: PhotoPickerRouter?
    
    init() {
    }
}
