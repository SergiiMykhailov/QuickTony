//
//  RealmConvertible.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import RealmSwift


protocol RealmConvertible
{
	associatedtype T: Object
	
	func encode() -> T
	static func decode(from: T) -> Self
}
