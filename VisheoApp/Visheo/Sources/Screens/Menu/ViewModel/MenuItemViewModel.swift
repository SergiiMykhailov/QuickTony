//
//  MenuItemViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol MenuItemViewModel {
    var text : String? {get}
    var image : UIImage? {get}
}


struct VisheoMenuItemViewModel : MenuItemViewModel {
    let text: String?
    let image: UIImage?
    
    let type : MenuItemType
}
