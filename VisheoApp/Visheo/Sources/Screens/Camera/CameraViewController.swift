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
	@IBOutlet weak var rotationHintView: UIView!
	@IBOutlet weak var cameraPreview: GPUImageView!
	@IBOutlet weak var rotationHintTrailing: NSLayoutConstraint!
	@IBOutlet weak var rotationHintLeading: NSLayoutConstraint!
	@IBOutlet weak var cameraRecordButton: CameraRecordButton!
	@IBOutlet weak var cameraToggleButton: UIButton!
	@IBOutlet weak var recordingStatusView: UIView!
	@IBOutlet weak var recordingIndicator: CameraRecordIndicator!
    @IBOutlet weak var countdownLabel: UILabel!
    @IBOutlet weak var prompterViewController: UIView!
	
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

        if (!viewModel.isPrompterAvailable) {
            navigationItem.rightBarButtonItem = nil
        }
        
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
		
		viewModel.deviceOrientationChangeBlock = { [weak self] orientation in
			DispatchQueue.main.async {
				self?.handleDeviceRotation(orientation)
			}
		}
        
        viewModel.didChanged = { [weak self] in
            DispatchQueue.main.async {
                self?.updateFromViewModel()
            }
        }
		
		let mask = CAShapeLayer();
		rotationHintView.layer.mask = mask;
		rotationHintView.alpha = 0.0;
        
        updateFromViewModel()
	}
	
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated);
        
        if isMovingToParentViewController && viewModel.shouldPresentCameraTips {
            displayTipsController();
        }
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated);
		viewModel.startCapture();
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		viewModel.stopCapture(teardown: isMovingFromParentViewController)
		super.viewWillDisappear(animated);
	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews();
		guard let mask = rotationHintView.layer.mask as? CAShapeLayer, !mask.frame.equalTo(rotationHintView.bounds) else {
			return;
		}
		mask.frame = rotationHintView.bounds;
		mask.path = UIBezierPath(roundedRect: rotationHintView.bounds, byRoundingCorners: [.bottomLeft, .bottomRight], cornerRadii: CGSize(width: 6.0, height: 6.0)).cgPath;
	}
	
    func updateFromViewModel() {
        prompterViewController.isHidden = !self.viewModel.isPrompterEnabled
        self.navigationItem.rightBarButtonItem = tipsBarButtonItem
    }
	
    var tipsBarButtonItem: UIBarButtonItem {
        let icon = !viewModel.isPrompterEnabled ? #imageLiteral(resourceName: "tipsIcon_black") : #imageLiteral(resourceName: "tipsIcon")
        let tipsButton = UIButton(type: .custom)
        tipsButton.frame = CGRect(origin: .zero, size: icon.size)
        tipsButton.setImage(icon, for: .normal)
        tipsButton.addTarget(self, action: #selector(CameraViewController.togglePrompterMode), for: .touchUpInside);

        return UIBarButtonItem(customView: tipsButton)
    }
    
	//MARK: - Actions
	
	@IBAction func toggleVideoRecording() {
		viewModel.toggleRecording()
	}
	
	@IBAction func toggleCameraFace() {
		viewModel.toggleCameraFace()
	}
    
    @objc func togglePrompterMode() {
        viewModel.togglePrompterMode()
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
			cameraRecordButton.isEnabled = false;
		} else {
			countdownLabel.isHidden = true;
			cameraRecordButton.isEnabled = true;
		}
		
		rotationHintView.isHidden = false;
		
		if case .stopped = update {
			cameraRecordButton.isRecording = false;
			cameraToggleButton.isHidden = false;
			rotationHintView.isHidden = true;
		} else {
			cameraRecordButton.isRecording = true;
			cameraToggleButton.isHidden = true;
			rotationHintView.isHidden = false;
		}
	}
	
	private func handleDeviceRotation(_ orientation: UIInterfaceOrientationMask)
	{
		let translationX = (rotationHintView.bounds.width - rotationHintView.bounds.height) / 2.0;
		
//		var animations:
		
		var fromConstraint: NSLayoutConstraint?;
		var toLayoutConstraint: NSLayoutConstraint?;
		var transform: CGAffineTransform = .identity;
		
		switch orientation {
			case .landscapeLeft:
//				rotationHintView.alpha = 1;
				fromConstraint = rotationHintTrailing;
				toLayoutConstraint = rotationHintLeading;
				toLayoutConstraint?.constant = -view.bounds.width;
				let rotation = CGAffineTransform(rotationAngle: -.pi/2);
				let translation = CGAffineTransform(translationX: -translationX, y: 0.0);
				transform = rotation.concatenating(translation);
			case .landscapeRight:
//				rotationHintView.alpha = 1;
				fromConstraint = rotationHintLeading;
				toLayoutConstraint = rotationHintTrailing;
				toLayoutConstraint?.constant = -view.bounds.width;
				let rotation = CGAffineTransform(rotationAngle: .pi/2);
				let translation = CGAffineTransform(translationX: translationX, y: 0.0);
				transform = rotation.concatenating(translation);
			default:
				break;
		}
		
		guard let _ = fromConstraint, let _ = toLayoutConstraint else {
			UIView.animate(withDuration: 0.05, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
				self.rotationHintView.alpha = 0.0;
			}, completion: nil);
			return;
		}
		
		self.rotationHintView.alpha = 0.0;
		self.rotationHintView.transform = transform;
		fromConstraint?.isActive = false;
		toLayoutConstraint?.isActive = true;
		self.view.layoutIfNeeded();
		
		UIView.animate(withDuration: 0.3, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
			toLayoutConstraint?.constant = 0.0;
			fromConstraint?.constant = 0.0;
			self.rotationHintView.alpha = 1.0;
			self.view.layoutIfNeeded();
		}, completion: nil)
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
            self?.viewModel.markCameraTipsSeen()
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
