//
//  CameraViewController.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import GPUImage

class CameraViewController: UIViewController
{
	@IBOutlet weak var cameraPreview: GPUImageView!
	@IBOutlet weak var cameraRecordButton: CameraRecordButton!
	@IBOutlet weak var cameraToggleButton: UIButton!
	
	
	//MARK: - VM+Router init
	
	private(set) var viewModel: CameraViewModel!
	private(set) var router: FlowRouter!
	
	func configure(viewModel: CameraViewModel, router: FlowRouter) {
		self.viewModel = viewModel
		self.router    = router
	}
	
	
	//MARK: - Lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		viewModel.addPreviewOutput(cameraPreview);
		
		viewModel.recordingStateChangedBlock = { [weak self] _ in
			guard let `self` = self else { return }
			DispatchQueue.main.async {
				self.cameraRecordButton.isSelected = self.viewModel.isRecording;
				self.cameraToggleButton.isHidden = self.viewModel.isRecording;
			}
		}
		
		viewModel.cameraReadinessChangeBlock = { [weak self] state in
			guard let `self` = self else { return }
			DispatchQueue.main.async {
				switch state {
					case .ready:
						self.hidePermissions();
					case .needsPermissions(let enableViaSettings):
						self.displayPermissions(enableViaSettings: enableViaSettings);
				}
			}
		}
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated);
		
		guard isMovingToParentViewController else {
			return;
		}
		
		viewModel.prepareCamera()
	}
	
	
	//MARK: - Actions
	
	@IBAction func toggleVideoRecording() {
		viewModel.toggleRecording();
	}
	
	@IBAction func toggleCameraFace() {
		viewModel.toggleCameraFace()
	}
	
	@IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
		navigationController?.popViewController(animated: true);
	}
}

extension CameraViewController {
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

extension CameraViewController {
	//MARK: - Permissions
	func displayPermissions(enableViaSettings: Bool)
	{
		
	}
	
	
	func hidePermissions()
	{
		
	}
}
