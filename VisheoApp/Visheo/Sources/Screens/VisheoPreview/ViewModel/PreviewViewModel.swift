//
//  PreviewViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol PreviewViewModel : class {
}

class VisheoPreviewViewModel : PreviewViewModel {
    weak var router: PreviewRouter?
    
    init() {
    }
}
