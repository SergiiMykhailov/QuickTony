//
//  TipsViewController.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class TipsViewController: UIViewController {
	
	//MARK: - VM+Router init
	
	private(set) var viewModel: TipsViewModel!
	private(set) var router: FlowRouter!
	
	func configure(viewModel: TipsViewModel, router: FlowRouter) {
		self.viewModel = viewModel
		self.router    = router
	}
	
	
	@IBOutlet weak var noWordsTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var hasWordsTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var practicesCollectionView: UICollectionView!
	@IBOutlet weak var wordIdeasCollectionView: UICollectionView!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	private var collectionViewMediator: TipsCollectionViewMediator?;
	
	override func viewDidLoad() {
		super.viewDidLoad();
		
		collectionViewMediator = TipsCollectionViewMediator(viewModel: viewModel,
															wordIdeasCollectionView: wordIdeasCollectionView,
															practicesCollectionView: practicesCollectionView,
															containerWidth: view.bounds.width);
		
		viewModel.activeSectionChanged = { [weak self] section in
			DispatchQueue.main.async {
				self?.update(with: section);
			}
		}
		
		viewModel.contentChanged = { [weak self] in
			DispatchQueue.main.async {
				self?.handleContentChange()
			}
		}
		
		update(with: viewModel.activeSection);
		handleContentChange();
	}
	
	@IBAction func switchedSection(_ sender: UISegmentedControl) {
		if let section = TipsSection(rawValue: sender.selectedSegmentIndex) {
			viewModel.switchSection(to: section);
		}
	}
	
	@IBAction func backPressed(_ sender: Any) {
		dismiss(animated: true, completion: nil);
	}
	
	private func update(with section: TipsSection) {
		let hidden = (section != .words);
		wordIdeasCollectionView.isHidden = hidden;
		practicesCollectionView.isHidden = !hidden;
		
		wordIdeasCollectionView.setContentOffset(.zero, animated: false);
		practicesCollectionView.setContentOffset(.zero, animated: false);
	}
	
	private func handleContentChange() {
		wordIdeasCollectionView.reloadData();
		practicesCollectionView.reloadData();
		
		collectionViewMediator?.handleContentChange();
		
		hasWordsTopConstraint?.isActive = viewModel.displaysWordsSection;
		view.layoutIfNeeded();
	}
}
