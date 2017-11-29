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
    @IBOutlet weak var downloadIndicator: UIView!
    @IBOutlet weak var titleLabel: UILabel!
	
	
	func setup(with cellModel: SoundtrackCellModel) {
	}
}
