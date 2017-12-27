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
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		var frame = layoutAttributes.frame;
		frame.origin.y = 0.0;
		
		let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes;
		attributes.frame = frame;
		return attributes;
	}
	
	func setup(with model: WordTipCellModel) {
		textLabel.text = model.text;
	}
}
