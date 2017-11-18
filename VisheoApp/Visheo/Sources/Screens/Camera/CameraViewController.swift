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
	@IBOutlet weak var recordingStatusView: UIView!
	@IBOutlet weak var recordingIndicator: CameraRecordIndicator!
	@IBOutlet weak var countdownLabel: UILabel!
	
	//MARK: - VM+Router init
	
	private(set) var viewModel: CameraViewModel!
	private(set) var router: FlowRouter!
	
	func configure(viewModel: CameraViewModel, router: FlowRouter) {
		self.viewModel = viewModel
		self.router    = router
	}
	
	//MARK: - Lifecycle

	override func viewDidLoad()
	{
		super.viewDidLoad()
	
		let tipsButton = UIButton(type: .custom);
		tipsButton.setImage(UIImage(named: "tipsIcon"), for: .normal);
		navigationItem.rightBarButtonItem = UIBarButtonItem(customView: tipsButton);
		
		viewModel.addPreviewOutput(cameraPreview);
		
		viewModel.recordingStateChangedBlock = { [weak self] update in
			DispatchQueue.main.async {
				self?.handleRecordingState(with: update);
			}
		}
		
		viewModel.recordingProgressChangedBlock = { [weak self] update in
			DispatchQueue.main.async {
				self?.cameraRecordButton.progress = update;
			}
		}
	}
	
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated);
		
		if isMovingToParentViewController {
			viewModel.startCapture();
		}
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated);
		
		if isMovingToParentViewController && viewModel.shouldPresentCameraTips {
			displayTipsController();
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		if isMovingFromParentViewController {
			viewModel.stopCapture();
		}
		
		super.viewWillDisappear(animated);
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
	
	private func handleRecordingState(with update: CameraRecordingState)
	{
		recordingStatusView.isHidden = (update != .recording);
		recordingIndicator.toggleAnimation(update == .recording);
		
		if case .countdown(let value) = update {
			countdownLabel.isHidden = false;
			countdownLabel.text = value;
		} else {
			countdownLabel.isHidden = true;
		}
		
		if case .stopped = update {
			cameraRecordButton.isRecording = false;
			cameraToggleButton.isHidden = false;
		} else {
			cameraRecordButton.isRecording = true;
			cameraToggleButton.isHidden = true;
		}
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
	//MARK: - Tips
	
	private func displayTipsController(onDisplay: (() -> Void)? = nil) {
		guard let buttonView = navigationItem.rightBarButtonItem?.customView, let navigationView = navigationController?.view else {
			return;
		}
		
		let tipsButtonFrame = navigationView.convert(buttonView.frame, from: buttonView.superview);
		
		let tipsView = CameraTipsView.display(in: navigationView, aligningTo: tipsButtonFrame, completion: onDisplay)
		
		tipsView?.tipsDismissedBlock = { [weak self] in
			self?.viewModel.markCameraTipsSeen();
		}
	}
}
