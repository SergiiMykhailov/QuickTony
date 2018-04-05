//
//  VideoTrimmingViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation
import PryntTrimmerView
import MBProgressHUD

class VideoTrimmingViewController: UIViewController {

    @IBOutlet weak var trimmingView: TrimmerView!
    @IBOutlet weak var videoContainer: VideoView!
    @IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
	
    override func viewDidLoad() {
        super.viewDidLoad()
        
		videoContainer.player = viewModel.player;
        
        viewModel.playbackTimeChanged = {[weak self] in
            self?.trimmingView.seek(to: $0)
        }
        
        viewModel.playbackStatusChanged = { [weak self] in
            self?.playButton.isHidden = ($0 == .playing)
        }
        
        viewModel.showProgressCallback = {[weak self] in
            guard let `self` = self else {return}
            if $0 {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
        
        if viewModel.hideBackButton {
            navigationItem.leftBarButtonItem = nil
        }
		
		navigationItem.rightBarButtonItem = viewModel.canCancelSelection ? cancelBarButtonItem : nil;
        
        viewModel.assetsChanged = {[weak self] in
			self?.videoContainer.player = self?.viewModel.player;
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        trimmingView.delegate = self
        viewModel.setup(trimmerView: trimmingView)
        viewModel.didChange(startTime: trimmingView.startTime, endTime: trimmingView.endTime, at: nil, stopMoving: true)
    }
    @IBAction func playPressed(_ sender: Any) {
        viewModel.togglePlayback()
    }
    
    @IBAction func retakePressed(_ sender: Any) {
        confirmGoingBack(retake: true)
    }
    
    @IBAction func videoTapped(_ sender: Any) {
        viewModel.togglePlayback()
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        viewModel.confirmTrimming()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        confirmGoingBack(retake: false)
    }
	
	@IBAction func cancelPressed(_ sender: Any) {
		if !viewModel.didMakeChangesInEditMode {
			viewModel.cancel();
			return;
		}
		
		let alertController = UIAlertController(title: NSLocalizedString("Notification", comment: "Notification alert title"),
												message: NSLocalizedString("Changes to your Video Wish won’t be applied", comment: "Cancelling edited video wish changes notification text"), preferredStyle: .alert)
		alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: NSLocalizedString("OK, Сontinue", comment: "OK, Сontinue button text"), style: .default, handler: { [weak self]_ in
			self?.viewModel.cancel()
		}))
		
		self.present(alertController, animated: true, completion: nil)
	}
	
    private func confirmGoingBack(retake: Bool) {
        if !retake {
            self.viewModel.goBack()
            return
        }
        
        let alertController = UIAlertController(title: NSLocalizedString("Notification", comment: "Notification alert title"),
                                                message: NSLocalizedString("Existing video wish will be replaced with the new one", comment: "New video recording notification text"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK, Сontinue", comment: "OK, Сontinue button text"), style: .default, handler: {_ in
            self.viewModel.retakeVideo()
        }))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - VM+Router init

    private(set) var viewModel: VideoTrimmingViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: VideoTrimmingViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
}

extension VideoTrimmingViewController: TrimmerViewDelegate {
    func positionBarStoppedMoving(_ playerTime: CMTime) {
        viewModel.didChange(startTime: trimmingView.startTime, endTime: trimmingView.endTime, at: playerTime, stopMoving: true)
    }
    
    func didChangePositionBar(_ playerTime: CMTime) {
        viewModel.didChange(startTime: trimmingView.startTime, endTime: trimmingView.endTime, at: playerTime, stopMoving: false)
    }
}

extension VideoTrimmingViewController {
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
