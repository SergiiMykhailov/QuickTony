//
//  VideoView.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation

class VideoView: UIView {

	override class var layerClass: Swift.AnyClass {
		return AVPlayerLayer.self;
	}
	
	
	var playerLayer: AVPlayerLayer {
		return layer as! AVPlayerLayer;
	}
	
	var player: AVPlayer? {
		get {
			return playerLayer.player;
		}
		
		set {
			playerLayer.player = newValue;
		}
	}

}
