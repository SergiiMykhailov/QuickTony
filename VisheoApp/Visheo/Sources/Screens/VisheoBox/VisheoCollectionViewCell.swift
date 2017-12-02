//
//  VisheoCollectionViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage

class VisheoCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    
    
    func configure(with vm: VisheoCellViewModel) {
        coverImage.sd_setImage(with: vm.coverUrl, completed: nil)
        titleLabel.text = vm.visheoTitle
    }
}
