//
//  VideoTrimmingViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation

class VideoTrimmingViewController: UIViewController {

    var player : AVPlayer!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let playerItem = AVPlayerItem(url: viewModel.videoUrl)
        player = AVPlayer(playerItem: playerItem)
        
//        NotificationCenter.default.addObserver(self, selector: #selector(VideoTrimmerViewController.itemDidFinishPlaying(_:)),
//                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        let layer: AVPlayerLayer = AVPlayerLayer(player: player)
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: videoContainer.frame.width, height: videoContainer.frame.height)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoContainer.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        videoContainer.layer.addSublayer(layer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        player.play()
    }
    
    //MARK: - VM+Router init
    
    @IBOutlet weak var videoContainer: UIView!
    
    private(set) var viewModel: VideoTrimmingViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: VideoTrimmingViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
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
