//
//  ProgressIndicator.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class ProgressIndicator: UIView
{
	private let trackLayer = CAShapeLayer();
	private let progressLayer = CAShapeLayer();
	
	
	@IBInspectable var trackColor: UIColor = .gray {
		didSet {
			trackLayer.strokeColor = trackColor.cgColor;
		}
	}
	
	@IBInspectable var progressColor: UIColor = .blue {
		didSet {
			progressLayer.strokeColor = progressColor.cgColor;
		}
	}
	
	@IBInspectable var lineWidth: CGFloat = 3.0 {
		didSet {
			progressLayer.lineWidth = lineWidth;
			trackLayer.lineWidth = lineWidth;
		}
	}
	
	@IBInspectable var progress: CGFloat = 0.0 {
		didSet {
			progressLayer.strokeEnd = progress;
		}
	}


	override init(frame: CGRect) {
		super.init(frame: frame);
		commonInit()
	}
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder);
		commonInit();
	}
	
	private func commonInit()
	{
		backgroundColor = .clear;
		trackLayer.fillColor = UIColor.clear.cgColor;
		progressLayer.fillColor = UIColor.clear.cgColor;
		
		layer.addSublayer(trackLayer);
		layer.addSublayer(progressLayer);
		
		trackLayer.strokeColor = trackColor.cgColor;
		trackLayer.lineWidth = lineWidth;
		
		progressLayer.strokeColor = progressColor.cgColor;
		progressLayer.lineWidth = lineWidth;
		progressLayer.lineCap = kCALineCapRound;
		progressLayer.setAffineTransform(CGAffineTransform(rotationAngle: -.pi / 2.0));
		progressLayer.strokeStart = 0.0;
		progressLayer.strokeEnd = 0.0;
	}
	
	
	override func layoutSubviews()
	{
		super.layoutSubviews()
		
		if trackLayer.frame.equalTo(bounds) {
			return;
		}
		
		trackLayer.frame = bounds;
		progressLayer.frame = bounds;
		
		let path = UIBezierPath(ovalIn: bounds);
		
		trackLayer.path = path.cgPath;
		progressLayer.path = path.cgPath;
	}
}
