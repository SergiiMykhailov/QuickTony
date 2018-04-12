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
    
    @IBOutlet weak var menuItemSubText : UILabel!
    
    func setup(with viewModel: MenuItemViewModel) {
        menuItemText.text = viewModel.text
        menuItemImage.image = viewModel.image
        
        if (viewModel.subText != nil) {
            menuItemSubText.text = viewModel.subText
        } else {
            menuItemSubText.isHidden = true
        }
    }
    
}
