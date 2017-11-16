//
//  CoverCollectionViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage

class CoverCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var coverImage: UIImageView!
    
    func setup(with viewModel: CoverCellViewModel) {
        coverImage.sd_setImage(with: viewModel.imageURL, completed: nil)
    }
    
}
