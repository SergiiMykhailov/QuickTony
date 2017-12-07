//
//  ShareVisheoViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation
import SDWebImage

class ShareVisheoViewController: UIViewController {
	@IBOutlet weak var containerScrollView: UIScrollView!
	@IBOutlet weak var shareNowTrailingConstraint: NSLayoutConstraint!
	@IBOutlet weak var scrollContainer: UIView!
	@IBOutlet weak var shareNowLeadingConstraint: NSLayoutConstraint!
	@IBOutlet weak var shareReminderContainer: UIView!
	@IBOutlet weak var shareNowContainer: UIView!
	@IBOutlet weak var shareReminderBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var shareNowBottomConstraint: NSLayoutConstraint!
	
	override func viewDidLoad() {
		super.viewDidLoad()

        viewModel.creationStatusChanged = {[weak self] in
            self?.updateProgress()
        }
        
        viewModel.showRetryLaterError = { [weak self] in
            self?.showRetryError(text: $0)
        }
        
        viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
        
        viewModel.successAlertHandler = {[weak self] in
            self?.showSuccessAlertWithText(text: $0)
        }
		
		viewModel.notificationsAuthorization = { [weak self] in
			self?.showNotificationsAuthorizationAlertWithText(text: $0)
		}
		
		reminderDatePicker.date = viewModel.reminderDate;
		reminderDatePicker.minimumDate = viewModel.minimumReminderDate;
        coverImage.sd_setImage(with: viewModel.coverImageUrl, completed: nil)
        
        updateProgress()
		
        if viewModel.showBackButton {
            navigationItem.leftBarButtonItems = [backBarItem]
        } else {
            navigationItem.leftBarButtonItems = [menuBarItem]
        }
    }
    
    private func showRetryError(text : String) {
        let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Eroro alert title"), message: text, preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Retry", comment: "Retry visheo upload/render"), style: .default, handler: {[weak self] (action) in
            self?.viewModel.retry()
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Try Later", comment: "Try Later visheo upload/render"), style: .default, handler: {[weak self] (action) in
            self?.viewModel.tryLater()
        }))
        
        self.present(alert, animated: true, completion: nil)
    }
	
	private func showNotificationsAuthorizationAlertWithText(text: String) {
		let alert = UIAlertController(title: NSLocalizedString("Error", comment: "Eroro alert title"), message: text, preferredStyle: .alert)
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Open Settings", comment: ""), style: .default, handler: {[weak self] (action) in
			self?.viewModel.openSettings()
		}))
		
		alert.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil));
		
		self.present(alert, animated: true, completion: nil)
	}

    private func updateProgress() {
        switch viewModel.creationStatus {
        case .rendering(let progress):
            progressBar.progress = progress
            updateForRendering()
        case .uploading(let progress):
            progressBar.progress = progress
            updateForUploading()
        case .ready:
            updateForReadyState()
        }
    }
    
    private func updateForRendering() {
        progressBar.title = viewModel.renderingTitle
        interface(enable: false)
        menuBarItem.isEnabled = false
        deleteBarItem.isEnabled = false
    }
    
    private func updateForUploading() {
        progressBar.title = viewModel.uploadingTitle
        interface(enable: false)
        menuBarItem.isEnabled = true
        deleteBarItem.isEnabled = false
    }
    
    private func updateForReadyState() {
        menuBarItem.isEnabled = true
        deleteBarItem.isEnabled = true
        UIView.animate(withDuration: 0.3) {
            self.progressBar.alpha = 0.0
            self.coverImage.alpha = 0.0
        }
        interface(enable: true)
        linkText.text = viewModel.visheoLink
        if let visheoUrl = viewModel.visheoUrl {
            setupPlayer(with: visheoUrl)
        }
    }
    
    private func interface(enable: Bool) {
        downloadButton.isEnabled = enable
        shareTypeSegment.isEnabled = enable
        shareButton.isEnabled = enable
		remindMeButton.isEnabled = enable;
		reminderDatePicker.isEnabled = enable;
        shareView.alpha = enable ? 1.0 : 0.2
        downloadButton.alpha = enable ? 1.0 : 0.2
        linkText.alpha = enable ? 1.0 : 0.2
		remindMeButton.alpha = enable ? 1.0 : 0.2;
		reminderDatePicker.alpha = enable ? 1.0 : 0.2;
    }
    
    private var player : AVPlayer?
    @IBOutlet weak var playerLoadingActivity: UIActivityIndicatorView!
    
    private func setupPlayer(with url: URL) {
        let playerAsset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: playerAsset)
        player = AVPlayer(playerItem: playerItem)
		
		videoContainer?.player = player;
		videoContainer?.playerLayer.backgroundColor = UIColor.white.cgColor;
		
        NotificationCenter.default.addObserver(self, selector: #selector(ShareVisheoViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        player?.play()
        playButton.isHidden = true
        
        player?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.new, context: nil)
        
        playerLoadingActivity.isHidden = false
        playerLoadingActivity.startAnimating()
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if let player = object as? AVPlayer {
            if player.status == .readyToPlay {
                playerLoadingActivity.stopAnimating()
                playerLoadingActivity.isHidden = true
            }
        }
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        player?.seek(to: kCMTimeZero)
        playButton.isHidden = false
    }
    
    deinit {
		player?.removeObserver(self, forKeyPath: "status");
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: ShareViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: ShareViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
	
	@IBOutlet weak var reminderDatePicker: UIDatePicker!
	@IBOutlet weak var remindMeButton: UIButton!
    @IBOutlet weak var progressBar: LabeledProgressView!
    @IBOutlet weak var shareTypeSegment: UISegmentedControl!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var linkText: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var videoContainer: VideoView!
    @IBOutlet weak var playButton: UIButton!
    @IBOutlet var menuBarItem: UIBarButtonItem!
    @IBOutlet var backBarItem: UIBarButtonItem!
    @IBOutlet weak var deleteBarItem: UIBarButtonItem!
    
    
    @IBAction func sharePressed(_ sender: Any) {
        if let link = viewModel.visheoLink, let visheoUrl = URL(string: link) {
            UIApplication.shared.open(visheoUrl, options: [:], completionHandler: nil)
        }
    }
    
    @IBAction func downloadPressed(_ sender: Any) {
        viewModel.saveVisheo()
    }
    
    @IBAction func playerTapped(_ sender: Any) {
        guard let player = player else {return}
        
        if player.isPlaying {
            player.pause()
            playButton.isHidden = false
        } else {
            player.play()
            playButton.isHidden = true
        }
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func deletePressed(_ sender: Any) {
        let confirmation = UIAlertController(title: NSLocalizedString("Notification", comment: "Notification alert title"),
                                             message: NSLocalizedString("Are you sure you want to delete this Visheo? It will be deleted forever.", comment: "Visheo deletion confirmation"), preferredStyle: .alert)
        confirmation.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel text"), style: .cancel, handler: nil))
        
        confirmation.addAction(UIAlertAction(title: NSLocalizedString("YES, Delete it", comment: "Visheo deletion confirm text"), style: .destructive, handler: { (action) in
            self.viewModel.deleteVisheo()
        }))
        
        present(confirmation, animated: true, completion: nil)
    }
    
    @IBOutlet weak var deletePressed: UIBarButtonItem!
    @IBAction func playButtonPressed(_ sender: Any) {
        guard let player = player else {return}
        player.play()
        playButton.isHidden = true
    }
	
	@IBAction func shareTypeChanged(_ sender: UISegmentedControl) {
		
		let shareNow = (sender.selectedSegmentIndex == 0);
		
		shareNowTrailingConstraint.isActive = shareNow;
		shareNowLeadingConstraint.isActive = !shareNow;
		shareNowBottomConstraint.isActive = shareNow;
		shareReminderBottomConstraint.isActive = !shareNow;
		
		UIView.animateKeyframes(withDuration: 0.35, delay: 0.0, options: [.beginFromCurrentState, .calculationModeLinear], animations: {
			
			if shareNow {
				UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.2, animations: {
					self.containerScrollView.setContentOffset(.zero, animated: false);
				})
				UIView.addKeyframe(withRelativeStartTime: 0.3, relativeDuration: 0.7, animations: {
					self.view.layoutIfNeeded();
				})
			} else {
				UIView.addKeyframe(withRelativeStartTime: 0.0, relativeDuration: 0.7, animations: {
					self.view.layoutIfNeeded();
				})
				UIView.addKeyframe(withRelativeStartTime: 0.8, relativeDuration: 0.2, animations: {
					let frame = self.shareReminderContainer.frame;
					self.containerScrollView.scrollRectToVisible(frame, animated: true);
				})
			}
		}) { _ in
		}
	}
	
	@IBAction func setReminder(_ sender: UIButton) {
		viewModel.setReminderDate(reminderDatePicker.date);
	}
}

extension ShareVisheoViewController {
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
