//
//  CameraPermissionsViewController.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/18/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class CameraPermissionsViewController: UIViewController {

	@IBOutlet weak var actionButton: UIButton!
	
	
	//MARK: - VM+Router init
	
	private(set) var viewModel: CameraPermissionsViewModel!
	private(set) var router: FlowRouter!
	
	func configure(viewModel: CameraPermissionsViewModel, router: FlowRouter) {
		self.viewModel = viewModel
		self.router    = router
	}

	
	//MARK: - Actions
	
	@IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
		navigationController?.popViewController(animated: true);
	}
	
	@IBAction func actionButtonPressed() {
		viewModel.requestPermissions();
	}
}

extension CameraPermissionsViewController {
	//MARK: - Routing
	
	override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
		if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
			return false
		}
		
		return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		super.prepare(for: segue, sender: sender)
		router.prepare(for: segue, sender: sender)
	}
}
