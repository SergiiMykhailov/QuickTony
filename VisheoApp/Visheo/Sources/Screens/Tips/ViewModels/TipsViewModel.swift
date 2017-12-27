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
	func numberOfItems(for section: TipsSection) -> Int
	var activeSection: TipsSection { get }
	
	func switchSection(to new: TipsSection);
	
	var activeSectionChanged: ((TipsSection) -> Void)? { get set }
	var contentChanged: (() -> Void)? { get set }
	
	func practiceTipCellModel(at index: Int) -> PracticeTipCellModel;
	func wordTipCellModel(at index: Int) -> WordTipCellModel;
}

class VisheoTipsViewModel: TipsViewModel {
	weak var router: TipsRouter?
	
	var contentChanged: (() -> Void)?;
	
	var activeSectionChanged: ((TipsSection) -> Void)?
	private (set) var activeSection: TipsSection = .words {
		didSet {
			activeSectionChanged?(activeSection);
		}
	}
	
	private let tipsProvider: TipsProviderService;
	private let record: OccasionRecord;
	
	init(record: OccasionRecord, tipsProvider: TipsProviderService) {
		self.record = record;
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
	
	func switchSection(to new: TipsSection) {
		activeSection = new;
	}
	
	func numberOfItems(for section: TipsSection) -> Int {
		switch section {
			case .words:
				return record.words.count;
			case .practices:
				return tipsProvider.practiceTips.count;
		}
	}
	
	
	func practiceTipCellModel(at index: Int) -> PracticeTipCellModel {
		let item = tipsProvider.practiceTips[index];
		return VisheoPracticeTipCellModel(index: index + 1, title: item.title, text: item.text)
	}
	
	func wordTipCellModel(at index: Int) -> WordTipCellModel {
		let item = record.words[index];
		return VisheoWordTipCellModel(text: item.text);
	}
}
