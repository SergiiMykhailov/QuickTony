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
	
	@IBOutlet weak var collectionView: UICollectionView!
	@IBOutlet weak var segmentedControl: UISegmentedControl!
	
	override func viewDidLoad() {
		super.viewDidLoad();
	}
	
	@IBAction func switchedSection(_ sender: UISegmentedControl) {
	}
	
	@IBAction func backPressed(_ sender: Any) {
		dismiss(animated: true, completion: nil);
	}
}
