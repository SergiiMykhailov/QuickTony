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
	private let statusLayer = CAShapeLayer();
	
	
	var progress: CGFloat = 0.0 {
		didSet {
			progressLayer.strokeEnd = progress;
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
		statusLayer.fillColor = UIColor.clear.cgColor;
		
		outerRingLayer.lineWidth = ringLayerLineWidth;
		outerRingLayer.strokeColor = ringLayerColor.cgColor;
		
		progressLayer.lineWidth = 4.0;
		progressLayer.strokeColor = progressTrackColor.cgColor;
		progressLayer.strokeStart = 0.0;
		progressLayer.strokeEnd = 0.5;
		progressLayer.setAffineTransform(CGAffineTransform(rotationAngle: -.pi / 2.0));
		
		layer.addSublayer(outerRingLayer);
		layer.addSublayer(progressLayer);
		layer.addSublayer(statusLayer);
	}
	
	
	override func layoutSubviews()
	{
		super.layoutSubviews();
		
		let minDimension = min(bounds.width, bounds.height);
		
		let outerRingFrame = CGRect(x: bounds.midX - minDimension / 2.0, y: bounds.midY - minDimension / 2.0, width: minDimension, height: minDimension);
		
		if !outerRingFrame.equalTo(outerRingLayer.frame)
		{
			outerRingLayer.frame = outerRingFrame;
			progressLayer.frame = outerRingFrame;
			
			var pathRect = outerRingFrame;
			pathRect.origin = .zero;
			pathRect = pathRect.insetBy(dx: ringLayerLineWidth / 2.0, dy: ringLayerLineWidth / 2.0);
			
			outerRingLayer.path = UIBezierPath(ovalIn: pathRect).cgPath;
			
			pathRect = outerRingFrame;
			pathRect.origin = .zero;
			pathRect = pathRect.insetBy(dx: (ringLayerLineWidth - 4.0) / 2.0, dy: (ringLayerLineWidth - 4.0) / 2.0);
			progressLayer.path = UIBezierPath(ovalIn: pathRect).cgPath;
		}
	}
	
	
	override var isSelected: Bool {
		didSet {

		}
	}
}
