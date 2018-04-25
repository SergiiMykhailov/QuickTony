//
//  TipsViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


enum TipsSection: Int {
	case words = 0
	case practices = 1
}

protocol TipsViewModel: class {
	func numberOfItems() -> Int
	
	var contentChanged: (() -> Void)? { get set }
	
	func practiceTipCellModel(at index: Int) -> PracticeTipCellModel
}

class VisheoTipsViewModel: TipsViewModel {
	weak var router: TipsRouter?
	
	var contentChanged: (() -> Void)?
	
	private let tipsProvider: TipsProviderService;
	
	init(tipsProvider: TipsProviderService) {
		self.tipsProvider = tipsProvider;
		
		NotificationCenter.default.addObserver(forName: .occasionsChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.contentChanged?();
		}
		
		NotificationCenter.default.addObserver(forName: .practiceTipsDidChange, object: nil, queue: OperationQueue.main) { [weak self] _ in
			self?.contentChanged?();
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self);
	}
	
	func numberOfItems() -> Int {
        return tipsProvider.practiceTips.count;
	}
	
	
	func practiceTipCellModel(at index: Int) -> PracticeTipCellModel {
		let item = tipsProvider.practiceTips[index];
		return VisheoPracticeTipCellModel(index: index + 1, title: item.title, text: item.text)
	}

}
