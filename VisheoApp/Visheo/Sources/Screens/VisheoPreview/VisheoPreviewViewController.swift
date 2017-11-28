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
		
//		viewModel.renderPreview()
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
		videoContainer.pause();
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
    }
    
    @IBAction func sendPressed(_ sender: Any) {
        viewModel.sendVisheo()
    }
	
	@IBAction func togglePlayback() {
		videoContainer.togglePlayback();
	}
	
	private func handle(renderStatus status: PreviewRenderStatus)
	{
		statusLabel.text = viewModel.statusText(for: status);
		
		switch status {
			case .ready(let item):
				videoContainer.item = item;
				videoContainer.play();
			default:
				videoContainer.pause();
				videoContainer.item = nil;
		}
		
		if case .rendering = status {
			activityIndicator.startAnimating();
			statusLabel.isHidden = false;
		} else {
			activityIndicator.stopAnimating();
			statusLabel.isHidden = true;
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
