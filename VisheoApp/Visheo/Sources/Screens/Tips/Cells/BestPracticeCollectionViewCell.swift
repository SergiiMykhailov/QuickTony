//
//  BestPracticeCollectionViewCell.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class BestPracticeCollectionViewCell: UICollectionViewCell {
	@IBOutlet weak var sectionLabel: UILabel!
	@IBOutlet weak var titleLabel: UILabel!
	@IBOutlet weak var textLabel: UILabel!
	
	override func preferredLayoutAttributesFitting(_ layoutAttributes: UICollectionViewLayoutAttributes) -> UICollectionViewLayoutAttributes {
		let bounding = CGSize(width: layoutAttributes.bounds.width, height: UILayoutFittingCompressedSize.height);
		
		layoutIfNeeded()
		let fitting = systemLayoutSizeFitting(bounding);
		
		var frame = layoutAttributes.frame;
		frame.size = CGSize(width: bounding.width, height: ceil(fitting.height));
		let attributes = layoutAttributes.copy() as! UICollectionViewLayoutAttributes;
		attributes.frame = frame;
		
		return attributes;
	}
	
	
	func setup(with model: PracticeTipCellModel) {
		sectionLabel.text = model.index;
		titleLabel.text = model.title;
		textLabel.text = model.text;
	}
}
