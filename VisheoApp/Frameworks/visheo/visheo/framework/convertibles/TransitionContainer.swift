//
//  TransitionContainer.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/22/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import UIKit
import AVFoundation


enum TransitionPart
{
	case from
	case to
}


class TransitionContainer
{
	private let container = CALayer();
	private let fromLayer = CALayer();
	private let toLayer = CALayer();
	
	
	var animatableLayer: CALayer {
		return container;
	}
	
	
	init(size: CGSize)
	{
		let frame = CGRect(origin: .zero, size: size);
		
		container.frame = frame;
		
		toLayer.frame = frame;
		fromLayer.frame = frame;
		
		container.addSublayer(toLayer);
		container.addSublayer(fromLayer);
	}
	
	
	func set(contents: UIImage, for layer: TransitionPart)
	{
		switch layer
		{
			case .from:
				fromLayer.contents = contents.cgImage;
			case .to:
				toLayer.contents = contents.cgImage;
		}
	}
	
	
	func animate(with animations: [ TransitionPart : CAAnimation ])
	{
		if let animation = animations[.from] {
			animation.beginTime = AVCoreAnimationBeginTimeAtZero;
			fromLayer.add(animation, forKey: "from");
		}
		
		if let animation = animations[.to] {
			animation.beginTime = AVCoreAnimationBeginTimeAtZero;
			toLayer.add(animation, forKey: "to");
		}
	}
}
