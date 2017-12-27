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
	var playbackStatusChanged: ((_ isPlaying: Bool) -> Void)? = nil;
	
	
	override init(frame: CGRect) {
		super.init(frame: frame);
		commonInit();
	}
	
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder);
		commonInit();
	}
	
	private func commonInit() {
		let recognizer = UITapGestureRecognizer(target: self, action: #selector(VisheoPreviewView.pausePlayback));
		addGestureRecognizer(recognizer);
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self);
	}
	
	
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
		if let playerItem = item {
			player = AVPlayer(playerItem: playerItem);
		} else {
			player = nil;
		}
	}
	
	
	var isPlaying: Bool {
		guard let `player` = player else {
			return false;
		}
		
		switch player.timeControlStatus {
			case .playing:
				return true;
			default:
				return false;
		}
	}
	
	
	func togglePlayback() {
		if isPlaying {
			pause();
		} else {
			play();
		}
	}
	
	
	func play() {
		player?.play();
		playbackStatusChanged?(true)
	}
	
	func pause() {
		player?.pause();
		playbackStatusChanged?(false)
	}
	
	func stop() {
		pause()
		player?.seek(to: kCMTimeZero);
	}
	
	
	@objc private func playerDidPlayToEnd() {
		player?.seek(to: kCMTimeZero);
		playbackStatusChanged?(false)
	}
	
	
	@objc func pausePlayback() {
		if isPlaying {
			pause();
		}
	}
}
