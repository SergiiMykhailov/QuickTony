//
//  WordTipCellModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol WordTipCellModel: class {
	var text: String? { get }
}

class VisheoWordTipCellModel: WordTipCellModel {
	let text: String?;
	
	init(text: String?) {
		self.text = text;
	}
}
