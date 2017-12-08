//
//  CameraRecordButton.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class CameraRecordButton: UIControl
{
	private let outerRingLayer = CAShapeLayer();
	private let progressLayer = CAShapeLayer();
	private let statusKnobLayer = CAShapeLayer();
	
	
	var progress: Double = 0.0 {
		didSet {
			progressLayer.strokeEnd = CGFloat(progress);
		}
	}
	

	@IBInspectable var ringLayerColor: UIColor = .red {
		didSet {
			outerRingLayer.strokeColor = ringLayerColor.cgColor;
		}
	}
	
	
	@IBInspectable var ringLayerLineWidth: CGFloat = 16.0 {
		didSet {
			outerRingLayer.lineWidth = ringLayerLineWidth;
		}
	}
	
	
	@IBInspectable var progressTrackColor: UIColor = .white {
		didSet {
			progressLayer.strokeColor = progressTrackColor.cgColor;
		}
	}
	
	
	@IBInspectable var statusKnobColor: UIColor = .black {
		didSet {
			statusKnobLayer.fillColor = statusKnobColor.cgColor;
		}
	}
	
	
	override init(frame: CGRect) {
		super.init(frame: frame);
		commonInit();
	}
	
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder);
		commonInit();
	}
	
	
	private func commonInit()
	{
		outerRingLayer.fillColor = UIColor.clear.cgColor;
		progressLayer.fillColor = UIColor.clear.cgColor;
		statusKnobLayer.fillColor = statusKnobColor.cgColor;
		
		outerRingLayer.lineWidth = ringLayerLineWidth;
		outerRingLayer.strokeColor = ringLayerColor.cgColor;
		
		progressLayer.lineCap = kCALineCapRound;
		progressLayer.lineWidth = 4.0;
		progressLayer.strokeColor = progressTrackColor.cgColor;
		progressLayer.strokeStart = 0.0;
		progressLayer.strokeEnd = 0.0;
		progressLayer.setAffineTransform(CGAffineTransform(rotationAngle: -.pi / 2.0));
		
		layer.addSublayer(outerRingLayer);
		layer.addSublayer(progressLayer);
		layer.addSublayer(statusKnobLayer);
	}
	
	
	override func layoutSubviews()
	{
		super.layoutSubviews();
		
		let minDimension = min(bounds.width, bounds.height);
		
		let outerRingFrame = CGRect(x: bounds.midX - minDimension / 2.0, y: bounds.midY - minDimension / 2.0, width: minDimension, height: minDimension);
		
		if outerRingFrame.equalTo(outerRingLayer.frame) {
			return;
		}
		
		var pathRect = outerRingFrame;
		pathRect.origin = .zero;
		pathRect = pathRect.insetBy(dx: ringLayerLineWidth / 2.0, dy: ringLayerLineWidth / 2.0);
		
		let statusKnobRadius = floor(minDimension * 0.3);
		let statusKnobFrame = CGRect(x: bounds.midX - statusKnobRadius / 2.0, y: bounds.midY - statusKnobRadius / 2.0, width: statusKnobRadius, height: statusKnobRadius);
		
		outerRingLayer.frame = outerRingFrame;
		progressLayer.frame = outerRingFrame;
		
		outerRingLayer.path = UIBezierPath(ovalIn: pathRect).cgPath;
		progressLayer.path = UIBezierPath(ovalIn: pathRect).cgPath;
		
		statusKnobLayer.frame = statusKnobFrame;
		updateStatusKnobPath();
	}
	
	
	private func updateStatusKnobPath(animated: Bool = false)
	{
		var rect = statusKnobLayer.frame;
		rect.origin = .zero;
		
		var path: UIBezierPath;
		
		if isRecording {
			path = UIBezierPath(roundedRect: rect,
								byRoundingCorners: .allCorners,
								cornerRadii: CGSize(width: rect.width / 5.0, height: rect.height / 5.0));
		} else {
			path = UIBezierPath(roundedRect: rect, cornerRadius: rect.width / 2.0);
		}
		
		if (!animated) {
			statusKnobLayer.removeAllAnimations();
			statusKnobLayer.path = path.cgPath;
			return;
		}
		
		let animation = CABasicAnimation(keyPath: "path");
		animation.duration = 0.1;
		animation.fromValue = statusKnobLayer.presentation()?.path;
		animation.toValue = path.cgPath;
		animation.fillMode = kCAFillModeBoth;
		animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut);
		animation.isRemovedOnCompletion = false;
		
		statusKnobLayer.add(animation, forKey: "knob");
	}
	
	
	var isRecording: Bool = false {
		didSet {
			updateStatusKnobPath(animated: true);
		}
	}
	
	override var isEnabled: Bool {
		didSet {
			UIView.animate(withDuration: 0.2, delay: 0.0, options: [.beginFromCurrentState, .curveEaseInOut], animations: {
				self.alpha = self.isEnabled ? 1.0 : 0.3;
			}, completion: nil);
		}
	}
}
