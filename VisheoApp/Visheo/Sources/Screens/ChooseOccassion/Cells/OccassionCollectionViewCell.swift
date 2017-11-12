//
//  OccassionCollectionViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage

class OccassionCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var occasionCoverImage: UIImageView!
    @IBOutlet weak var occasionNameLabel: UILabel!
    
    func setup(with viewModel: OccasionCellViewModel) {
        occasionNameLabel.text = viewModel.name
        occasionCoverImage.sd_setImage(with: viewModel.imageURL, completed: nil)
    }
}
