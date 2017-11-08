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
