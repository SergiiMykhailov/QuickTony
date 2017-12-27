//
//  AutoSizingLayout.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class AutoSizingLayout: UICollectionViewFlowLayout {
	override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
		guard let `collectionView` = collectionView else {
			return false;
		}
		switch scrollDirection {
		case .vertical:
			return newBounds.width != collectionView.bounds.width;
		case .horizontal:
			return newBounds.height != collectionView.bounds.height;
		}
	}
	
	override func shouldInvalidateLayout(forPreferredLayoutAttributes preferredAttributes: UICollectionViewLayoutAttributes, withOriginalAttributes originalAttributes: UICollectionViewLayoutAttributes) -> Bool {
		return !preferredAttributes.frame.equalTo(originalAttributes.frame);
	}
}
