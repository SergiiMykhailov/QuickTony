//
//  HolidayCollectionViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage
import BadgeSwift

class HolidayCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var holidayCoverImage: UIImageView!
    @IBOutlet weak var holidayDateLabel: UILabel!
    @IBOutlet weak var holidayFreeLabel: BadgeSwift!
    
    func setup(with viewModel: HolidayCellViewModel) {
		holidayDateLabel.isHidden = !viewModel.displaysDate;
        holidayDateLabel.text = viewModel.holidayDateText
        holidayCoverImage.sd_setImage(with: viewModel.imageURL, completed: nil)
        holidayFreeLabel.isHidden = !viewModel.isFree
    }    
}
