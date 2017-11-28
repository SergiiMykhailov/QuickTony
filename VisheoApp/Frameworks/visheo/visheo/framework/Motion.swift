//
//  Motion.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/28/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import UIKit


enum Motion
{
	case left
	case right
	case top
	case bottom
	case zoom
}


extension Motion
{
	static func motionForAsset(sized assetSize: CGSize, inBounds boundingSize: CGSize) -> Motion
	{
		if assetSize.isLessOrClose(to: boundingSize) {
			return .zoom;
		}
		
		let side = arc4random_uniform(2);
		
		if (assetSize.width > assetSize.height) {
			return side > 0 ? .left : .right;
		}
		
		if (assetSize.height > boundingSize.height) {
			return side > 0 ? .top : .bottom;
		}
		
		return .zoom;
	}
	
	
	func initialOffset(for assetSize: CGSize, inBounds boundingSize: CGSize) -> CGPoint
	{
		let horizontalOffset = (assetSize.width - boundingSize.width) / 2.0;
		let verticalOffset = (assetSize.height - boundingSize.height) / 2.0;
		
		var point = CGPoint.zero;
		
		switch self
		{
		case .zoom:
			return point;
		case .left:
			point.x = -horizontalOffset / 2.0;
		case .right:
			point.x = horizontalOffset / 2.0;
		case .top:
			point.y = -verticalOffset / 2.0;
		case .bottom:
			point.y = verticalOffset / 2.0;
		}
		
		return point;
	}
}
