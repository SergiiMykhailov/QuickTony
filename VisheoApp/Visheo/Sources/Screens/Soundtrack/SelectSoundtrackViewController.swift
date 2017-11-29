//
//  SelectSoundtrackViewController.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class SelectSoundtrackViewController: UIViewController {

	@IBOutlet weak var soundtracksCollectionView: UICollectionView!
	var soundtracksCollectionMediator : SoundtrackCollectionMediator?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		soundtracksCollectionMediator = SoundtrackCollectionMediator(viewModel: viewModel,
																	 collectionView: soundtracksCollectionView,
																	 containerWidth: view.bounds.width);
	}
	
	private(set) var viewModel: SelectSoundtrackViewModel!
	private(set) var router: FlowRouter!
	
	func configure(viewModel: SelectSoundtrackViewModel, router: FlowRouter) {
		self.viewModel = viewModel
		self.router    = router
	}

	
	@IBAction func confirmSelection() {
		viewModel.confirmSelection();
	}
	
	@IBAction func cancelSelection(_ sender: UIBarButtonItem) {
		viewModel.cancelSelection();
	}
}
