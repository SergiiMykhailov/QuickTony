//
//  Result.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/30/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Foundation

enum Result<T>
{
	case success(value: T)
	case failure(error: Error)
	
	
	var value: T?
	{
		switch self
		{
			case .success(let value):
				return value;
			default:
				return nil;
		}
	}
}
