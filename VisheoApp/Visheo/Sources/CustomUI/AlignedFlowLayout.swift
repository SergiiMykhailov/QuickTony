//
//  AlignedFlowLayout.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

enum FlowLayoutAlignment {
	case left
	case right
	case top
	case bottom
	case none
}

class AlignedFlowLayout: AutoSizingLayout
{
	private let alignment: FlowLayoutAlignment;
	
	init(alignment: FlowLayoutAlignment = .none) {
		self.alignment = alignment;
		super.init();
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
		guard let `collectionView` = collectionView, let attributes = super.layoutAttributesForElements(in: rect) else {
			return nil;
		}
		
		for attribute in attributes {
			var frame = attribute.frame;
			let bounds = collectionView.bounds;
			
			switch (alignment, scrollDirection) {
				case (.left, .vertical):
					frame.origin.x = sectionInset.left;
				case (.right, .vertical):
					frame.origin.x = bounds.width - frame.width - sectionInset.right;
				case (.top, .horizontal):
					frame.origin.y = sectionInset.top;
				case (.bottom, .horizontal):
					frame.origin.y = bounds.height - frame.height - sectionInset.bottom;
				default:
					continue;
			}
			attribute.frame = frame;
		}
		
		return attributes;
	}
}
