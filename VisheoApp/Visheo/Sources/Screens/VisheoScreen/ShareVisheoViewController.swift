//
//  ShareVisheoViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation

class ShareVisheoViewController: UIViewController {

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
        
        coverImage.image = UIImage(contentsOfFile: viewModel.coverImageUrl.path)
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
    }
    
    private func updateForUploading() {
        progressBar.title = viewModel.uploadingTitle
        interface(enable: false)
    }
    
    private func updateForReadyState() {
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
        shareView.alpha = enable ? 1.0 : 0.2
        downloadButton.alpha = enable ? 1.0 : 0.2
        linkText.alpha = enable ? 1.0 : 0.2
    }
    
    private var player : AVPlayer?
    
    private func setupPlayer(with url: URL) {
        let playerAsset = AVAsset(url: url)
        let playerItem = AVPlayerItem(asset: playerAsset)
        player = AVPlayer(playerItem: playerItem)
        
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: videoContainer.frame.width, height: videoContainer.frame.height)
        
        videoContainer.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        videoContainer.layer.addSublayer(layer)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ShareVisheoViewController.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        player?.play()
        playButton.isHidden = true
        
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        player?.seek(to: kCMTimeZero)
        playButton.isHidden = false
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: ShareViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: ShareViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBOutlet weak var progressBar: LabeledProgressView!
    @IBOutlet weak var shareTypeSegment: UISegmentedControl!
    @IBOutlet weak var downloadButton: UIButton!
    @IBOutlet weak var shareButton: UIButton!
    @IBOutlet weak var shareView: UIView!
    @IBOutlet weak var linkText: UILabel!
    @IBOutlet weak var coverImage: UIImageView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var playButton: UIButton!
    
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
    
    @IBAction func playButtonPressed(_ sender: Any) {
        guard let player = player else {return}
        player.play()
        playButton.isHidden = true
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
