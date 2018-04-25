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
	
	@IBOutlet weak var practicesCollectionView: UICollectionView!
	private var collectionViewMediator: TipsCollectionViewMediator?;
	
	override func viewDidLoad() {
		super.viewDidLoad();
		
		collectionViewMediator = TipsCollectionViewMediator(viewModel: viewModel,
															practicesCollectionView: practicesCollectionView,
															containerWidth: view.bounds.width);
		
		viewModel.contentChanged = { [weak self] in
			DispatchQueue.main.async {
				self?.handleContentChange()
			}
		}
        
		handleContentChange();
	}
	
	@IBAction func menuPressed(_ sender: Any) {
		self.showLeftViewAnimated(sender)
	}
	
	private func handleContentChange() {
		practicesCollectionView.reloadData();
        
		view.layoutIfNeeded();
	}
}
