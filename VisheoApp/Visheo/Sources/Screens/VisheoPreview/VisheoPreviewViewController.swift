//
//  VisheoPreviewViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation

class VisheoPreviewViewController: UIViewController {
	
	@IBOutlet weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet weak var playButton: UIButton!
	@IBOutlet weak var statusLabel: UILabel!
	@IBOutlet weak var videoContainer: VisheoPreviewView!
	
    override func viewDidLoad() {
        super.viewDidLoad()

		viewModel.previewRenderCallback = { [weak self] status in
			DispatchQueue.main.async {
				self?.handle(renderStatus: status);
			}
		}
		
		videoContainer.playbackStatusChanged = { [weak self] status in
			DispatchQueue.main.async {
				self?.handle(playbackStatus: status);
			}
		}
		
        viewModel.premiumUsageFailedHandler = { [weak self] in
            self?.handlePremiumCardUsageError()
        }
    }
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated);
		viewModel.renderPreview();
	}
	
    override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated);
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated);
		videoContainer.stop();
	}

    //MARK: - VM+Router init
    
    private(set) var viewModel: PreviewViewModel!
    private(set) var router: FlowRouter!
    
    @IBOutlet weak var tempImage: UIImageView!
    
    func configure(viewModel: PreviewViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
	
	@IBAction func backButtonPressed(_ sender: UIBarButtonItem) {
		navigationController?.popViewController(animated: true);
	}
    
    @IBAction func exitButtonPressed(_ sender: UIBarButtonItem) {
        self.handleExitButtonPress { [weak self] in
            self?.navigationController?.popToRootViewController(animated: true);
        }
    }
    
    @IBAction func editCover(_ sender: Any) {
        viewModel.editCover()
    }
    @IBAction func editPhotos(_ sender: Any) {
        viewModel.editPhotos()
    }
    
    @IBAction func editVideo(_ sender: Any) {
        viewModel.editVideo()
    }
    
    @IBAction func editSoundtrack(_ sender: Any) {
		viewModel.editSoundtrack();
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        viewModel.buttonSaveWasClicked()
    }
	
	@IBAction func togglePlayback() {
		videoContainer.togglePlayback();
	}
	
	private func handle(renderStatus status: PreviewRenderStatus)
	{
		let statusText = viewModel.statusText(for: status);
		statusLabel.text = statusText;
		statusLabel.isHidden = (statusText == nil);
		
		switch status {
			case .ready(let item):
				videoContainer.item = item;
				videoContainer.play();
			default:
				videoContainer.pause();
				videoContainer.item = nil;
		}
		
		if viewModel.isActivityRunning(for: status) {
			activityIndicator.startAnimating();
		} else {
			activityIndicator.stopAnimating();
		}
		
		if viewModel.shouldRetryRender(for: status) {
			viewModel.renderPreview();
		}
	}
	
	private func handle(playbackStatus isPlaying: Bool)
	{
		switch (isPlaying, viewModel.renderStatus)
		{
			case (false, .ready):
				playButton.isHidden = false;
			default:
				playButton.isHidden = true;
		}
	}
    
    private func handleExitButtonPress(withContinue continueHandler: @escaping () -> ()) {
        let alertController = UIAlertController(title: NSLocalizedString("Message", comment: "exit from preview message title"), message: NSLocalizedString("If you exit now you Visheo won't be saved", comment: "if you exit now you Visheo won't be saved"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Exit", comment: "Exit button text"), style: .destructive) { (action) in
            continueHandler()
        })
        
        present(alertController, animated: true, completion: nil)
        
    }
    
    private func handlePremiumCardUsageError() {
        let alertController = UIAlertController(title: NSLocalizedString("Oops…", comment: "error using premium card title"), message: NSLocalizedString("Something went wrong. Please check your Internet connection and try again.", comment: "something went wrong while suing premium card"), preferredStyle: .alert)

        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: "Try again button text"), style: .default) { (action) in
            self.viewModel.sendVisheo()
        })
            
        present(alertController, animated: true, completion: nil)
    }
}


extension VisheoPreviewViewController {
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
