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
    
    @IBOutlet weak var labeledProgress: LabeledProgressView!
    
    func configure(with vm: VisheoCellViewModel, animateProgress: Bool = false) {
        coverImage.sd_setImage(with: vm.coverUrl, completed: nil)
        titleLabel.text = vm.visheoTitle
        
        labeledProgress.set(progress: vm.uploadProgress, animated: animateProgress)
        
        let uploadingStateChange = {[weak self] in
            self?.labeledProgress.isHidden = !vm.isUploading
            self?.coverImage.alpha = vm.isUploading ? 0.4 : 1.0
        }
        
        if animateProgress {
            UIView.animate(withDuration: 0.3, animations: uploadingStateChange)
        } else {
            uploadingStateChange()
        }
    }
}
