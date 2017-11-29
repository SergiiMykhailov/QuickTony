//
//  SelectSoundtrackViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SelectSoundtrackViewModel: class
{
	var soundtracksCount: Int { get }
	func soundtrackCellModel(at index: Int) -> SoundtrackCellModel
	
	func cancelSelection()
	func confirmSelection()
}


class VisheoSelectSoundtrackViewModel: SelectSoundtrackViewModel
{
	weak var router: SelectSoundtrackRouter?
	let occasion : OccasionRecord
	let permissionsService : AppPermissionsService
	let assets: VisheoRenderingAssets
	
	init(occasion: OccasionRecord, assets: VisheoRenderingAssets, permissionsService: AppPermissionsService, editMode: Bool = false) {
		self.occasion = occasion
		self.permissionsService = permissionsService
		self.assets = assets
	}
	
	var soundtracksCount: Int {
		return 5;
	}
	
	func soundtrackCellModel(at index: Int) -> SoundtrackCellModel {
		return VisheoSoundtrackCellModel()
	}
	
	
	func confirmSelection() {
		router?.goBack(with: assets);
	}
	
	func cancelSelection() {
		router?.goBack(with: assets);
	}
}
