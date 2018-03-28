//
//  OccassionCollectionViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage
import BadgeSwift

class OccassionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var occasionCoverImage: UIImageView!
    @IBOutlet weak var occasionNameLabel: UILabel!
    @IBOutlet weak var occasionFree: BadgeSwift!
    
    func setup(with viewModel: OccasionCellViewModel) {
        occasionNameLabel.text = viewModel.name
        occasionCoverImage.sd_setImage(with: viewModel.imageURL, completed: nil)
        occasionFree.isHidden = !viewModel.isFree
    }
}
