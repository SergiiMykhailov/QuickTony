//
//  PremiumCollectionViewCell.swift
//  Visheo
//
//  Created by Ivan on 4/27/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit
import SDWebImage
import BadgeSwift

class PremiumCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var occasionCoverImage: UIImageView!
    @IBOutlet weak var occasionFree: BadgeSwift!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    func setup(with viewModel: PremiumCellViewModel) {
        occasionFree.isHidden = !viewModel.isFree
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        occasionCoverImage.sd_setImage(with: viewModel.imageURL) { [weak self] _,_,_,_ in
            self?.activityIndicator.isHidden = true
        }
    }
}
