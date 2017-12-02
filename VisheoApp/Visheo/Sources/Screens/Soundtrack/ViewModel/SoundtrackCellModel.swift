//
//  SoundtrackCellModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SoundtrackCellModel {
	var title: String? { get }
	var selected: Bool { get }
	var progress: Double { get }
	var displaysProgress: Bool { get }
}


struct VisheoSoundtrackCellModel: SoundtrackCellModel
{
	let title: String?;
	let selected: Bool;
	let streamingProgress: Double?;
	
	init(title: String?, selected: Bool, progress: Double? = nil) {
		self.title = title;
		self.selected = selected;
		self.streamingProgress = progress;
	}
	
	static func empty(selected: Bool) -> VisheoSoundtrackCellModel {
		let title = NSLocalizedString("No Music", comment: "No Music sountrack cell title")
		return VisheoSoundtrackCellModel(title: title, selected: selected);
	}
	
	var displaysProgress: Bool {
		switch streamingProgress {
			case .none:
				return false;
			case .some(let value) where value >= 1.0:
				return false;
			default:
				return true;
		}
	}
	
	var progress: Double {
		return streamingProgress ?? 0.0;
	}
}
