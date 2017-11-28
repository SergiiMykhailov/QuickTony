//
//  Utils.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Foundation

func documentsDirectory() -> URL?
{
	guard let path = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first else {
		return nil;
	}
	
	return URL(fileURLWithPath: path);
}



extension CGSize
{
	func isLessOrClose(to other: CGSize, threshold: CGFloat = 3.0) -> Bool
	{
		if width < other.width && height < other.height {
			return true;
		}
		
		return fabs(width - height) < threshold &&
			fabs(width - other.width) < threshold &&
			fabs(height - other.height) < threshold;
	}
}
