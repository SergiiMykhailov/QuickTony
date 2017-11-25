//
//  VisheoPreviewView.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/24/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation

class VisheoPreviewView: UIView
{
	var item: AVPlayerItem? {
		
		willSet {
			NotificationCenter.default.removeObserver(self);
		}
		
		didSet {
			if let `item` = item {
				NotificationCenter.default.addObserver(self, selector: #selector(VisheoPreviewView.playerDidPlayToEnd), name: Notification.Name.AVPlayerItemDidPlayToEndTime, object: item);
			}
			updatePlayerItem()
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self);
	}
	
	override class var layerClass: Swift.AnyClass {
		return AVPlayerLayer.self;
	}
	
	
	private var playerLayer: AVPlayerLayer {
		return layer as! AVPlayerLayer;
	}
	
	private var player: AVPlayer? {
		get {
			return playerLayer.player;
		}
		
		set {
			playerLayer.player = newValue;
		}
	}
	
	private func updatePlayerItem() {
		guard let _ = item else {
			return;
		}

		player = AVPlayer(playerItem: item!)
	}
	
	
	func togglePlayback() {
		guard let `player` = player else {
			return;
		}
		
		switch player.timeControlStatus
		{
			case .playing:
				pause();
			default:
				play();
		}
	}
	
	
	func play() {
		player?.play();
	}
	
	func pause() {
		player?.pause();
	}
	
	
	@objc private func playerDidPlayToEnd() {
		player?.seek(to: kCMTimeZero);
		player?.play();
	}
}
