//
//  CustomAnimatable.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/6/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import UIKit
import AVFoundation

class CustomAnimatable: CALayer
{
	@NSManaged var brightness: CGFloat
	
	override init() {
		super.init()
	}
	
	override init(layer: Any) {
		super.init(layer: layer);
		
//		print("\(self) \(self.backgroundColor)")

		if let l = layer as? CustomAnimatable {
			self.brightness = l.brightness;
		}
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
//	override func action(forKey event: String) -> CAAction?
//	{
//		if event == "brightness" {
//			let animation = CABasicAnimation(keyPath: event);
//			animation.fromValue = presentation()?.brightness ?? self.brightness;
//			return animation;
//		}
//
//		return super.action(forKey: event);
//	}
	
	override class func needsDisplay(forKey key: String) -> Bool
	{
		if key == "brightness" {
			return true;
		}
		
		return super.needsDisplay(forKey: key);
	}
	
	
	override func draw(in ctx: CGContext) {
//		super.draw(in: ctx);
		
		let color = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: brightness);
		
		ctx.setFillColor(color.cgColor);
		ctx.fill(bounds);
//		print("\(self) \(String(describing: presentation()?.brightness)) \(self.brightness)")
	}
	
//	override func display()
//	{
//		print("\(self) \(String(describing: presentation()?.brightness)) \(self.brightness)")
//	}
}
