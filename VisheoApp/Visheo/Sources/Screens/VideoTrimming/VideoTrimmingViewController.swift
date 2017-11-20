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
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var playButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let layer = viewModel.createPlayerLayer()
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: videoContainer.frame.width, height: videoContainer.frame.height)
        
        videoContainer.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        videoContainer.layer.addSublayer(layer)
        
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
        confirmGoingBack()
    }
    
    @IBAction func videoTapped(_ sender: Any) {
        viewModel.togglePlayback()
    }
    
    @IBAction func continuePressed(_ sender: Any) {
        viewModel.confirmTrimming()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        confirmGoingBack()
    }
    
    private func confirmGoingBack() {
        let alertController = UIAlertController(title: NSLocalizedString("Notification", comment: "Notification alert title"),
                                                message: NSLocalizedString("Existing video wish will be replaced with the new one", comment: "New video recording notification text"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("OK, Сontinue", comment: "OK, Сontinue button text"), style: .default, handler: {_ in
            self.viewModel.cancelTrimming()
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
