//
//  CameraRecordIndicator.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/18/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class CameraRecordIndicator: UIView
{
    override func layoutSubviews() {
        super.layoutSubviews()
		layer.cornerRadius = bounds.height / 2.0;
    }
	
	func toggleAnimation(_ animate: Bool) {
		if animate {
			self.animate();
		} else {
			stopAnimating();
		}
	}
	
	func animate() {
		let animation = CABasicAnimation(keyPath: "opacity");
		animation.fromValue = 1.0;
		animation.toValue = 0.2;
		animation.autoreverses = true;
		animation.repeatCount = HUGE;
		animation.isRemovedOnCompletion = false;
		animation.duration = 0.6;
		
		layer.add(animation, forKey: "blink");
	}
	
	func stopAnimating() {
		layer.removeAllAnimations();
	}
}
