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

    @IBOutlet weak var videoContainer: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        let playerAsset = AVAsset(url: viewModel.assets.videoUrl)
        let playerItem = AVPlayerItem(asset: playerAsset)
        let player = AVPlayer(playerItem: playerItem)
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        layer.backgroundColor = UIColor.white.cgColor
        layer.frame = CGRect(x: 0, y: 0, width: videoContainer.frame.width, height: videoContainer.frame.height)
        
        videoContainer.layer.sublayers?.forEach({$0.removeFromSuperlayer()})
        videoContainer.layer.addSublayer(layer)
        player.play()
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: PreviewViewModel!
    private(set) var router: FlowRouter!
    
    @IBOutlet weak var tempImage: UIImageView!
    
    func configure(viewModel: PreviewViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
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
