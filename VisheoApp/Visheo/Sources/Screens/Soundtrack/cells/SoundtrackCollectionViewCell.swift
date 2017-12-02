//
//  SoundtrackCollectionViewCell.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class SoundtrackCollectionViewCell: UICollectionViewCell
{
    @IBOutlet weak var selectionIndicator: UIImageView!
    @IBOutlet weak var downloadIndicator: ProgressIndicator!
    @IBOutlet weak var titleLabel: UILabel!
	
	override func prepareForReuse() {
		super.prepareForReuse()
		downloadIndicator.isHidden = true;
		
		CATransaction.begin();
		CATransaction.setDisableActions(true)
		downloadIndicator.progress = 0.0;
		CATransaction.commit();
	}
	
	func setup(with cellModel: SoundtrackCellModel) {
		selectionIndicator.isHidden = !cellModel.selected;
		titleLabel.text = cellModel.title;
		downloadIndicator.isHidden = !cellModel.displaysProgress;
		downloadIndicator.progress = CGFloat(cellModel.progress);
	}
}
