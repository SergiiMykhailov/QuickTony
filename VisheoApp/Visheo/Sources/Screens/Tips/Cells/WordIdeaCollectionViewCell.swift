//
//  WordIdeaCollectionViewCell.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class WordIdeaCollectionViewCell: UICollectionViewCell {
    
	@IBOutlet weak var textLabel: UILabel!
	
	func setup(with model: WordTipCellModel) {
		textLabel.text = model.text;
	}
}
