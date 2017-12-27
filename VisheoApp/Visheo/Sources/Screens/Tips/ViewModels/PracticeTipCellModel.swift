//
//  PracticeTipCellModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol PracticeTipCellModel: class {
	var index: String { get }
	var title: String { get }
	var text: String { get }
}

class VisheoPracticeTipCellModel: PracticeTipCellModel {
	private let tipIndex: Int;
	let title: String;
	let text: String
	
	init(index: Int, title: String, text: String) {
		self.title = title;
		self.text = text;
		self.tipIndex = index;
	}
	
	var index: String {
		switch tipIndex {
			case ..<10:
				return "0\(tipIndex)"
			default:
				return "\(tipIndex)"
		}
	}
}
