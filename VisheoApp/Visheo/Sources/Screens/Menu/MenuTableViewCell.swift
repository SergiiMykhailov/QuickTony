//
//  MenuTableViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class MenuTableViewCell: UITableViewCell {

    @IBOutlet weak var menuItemImage: UIImageView!
    
    @IBOutlet weak var menuItemText: UILabel!
    
    func setup(with viewModel: MenuItemViewModel) {
        menuItemText.text = viewModel.text
        menuItemImage.image = viewModel.image
    }
    
}
