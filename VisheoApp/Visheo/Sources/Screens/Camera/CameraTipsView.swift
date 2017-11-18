//
//  CameraTipsView.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/18/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class CameraTipsView: UIView
{
	var tipsDismissedBlock: (() -> Void)? = nil;
	
	@IBOutlet weak var tipsIcon: UIImageView!
	private lazy var dimView = UIView();
	
	@IBInspectable var dimBackgroundViewAlpha: CGFloat = 0.5 {
		didSet {
			updateDimViewAppearance()
		}
	}
	
	@IBInspectable var dimBackgroundViewColor: UIColor = .black {
		didSet {
			updateDimViewAppearance();
		}
	}
	
	private func updateDimViewAppearance() {
		dimView.backgroundColor = dimBackgroundViewColor.withAlphaComponent(dimBackgroundViewAlpha);
	}
	
	@IBAction func dismissTips() {
		
		UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut,
					   animations: {
			self.dimView.alpha = 0.0;
			self.alpha = 0.0;
		})
		{ [weak self] _ in
			self?.tipsDismissedBlock?()
			self?.dimView.removeFromSuperview();
			self?.removeFromSuperview();
		}
	}
	
	
	@discardableResult
	class func display(in parent: UIView, aligningTo sourceRect: CGRect, completion: (() -> Void)? = nil) -> CameraTipsView? {
		
		let nib = UINib(nibName: "CameraTips", bundle: Bundle.main);
		let tipsView = nib.instantiate(withOwner: nil, options: nil).first as? CameraTipsView;
		
		tipsView?.display(in: parent, aligningTo: sourceRect, completion: completion);
		
		return tipsView;
	}
	
	func display(in parent: UIView, aligningTo sourceRect: CGRect, completion: (() -> Void)? = nil) {
		
		translatesAutoresizingMaskIntoConstraints = false;
		layoutIfNeeded()
		
		var origin = tipsIcon.frame.origin;
		origin.x = sourceRect.minX - origin.x;
		origin.y = sourceRect.minY - origin.y;
		
		updateDimViewAppearance()
		dimView.alpha = 0.0;
		dimView.translatesAutoresizingMaskIntoConstraints = false;
		parent.addSubview(dimView);
		
		let dimViewAttributes: [NSLayoutAttribute] = [.leading, .trailing, .top, .bottom];
		
		for attribute in dimViewAttributes {
			let constraint = NSLayoutConstraint(item: dimView, attribute: attribute, relatedBy: .equal, toItem: parent, attribute: attribute, multiplier: 1, constant: 0.0)
			constraint.isActive = true;
		}

		alpha = 0.0;
		parent.addSubview(self);
		
		let tipsViewAttributes = [ NSLayoutAttribute.leading : origin.x,
								   NSLayoutAttribute.top : origin.y ]
		
		for (key, value) in tipsViewAttributes {
			let constraint = NSLayoutConstraint(item: self, attribute: key, relatedBy: .equal, toItem: parent, attribute: key, multiplier: 1, constant: value);
			constraint.isActive = true;
		}
		
		layoutIfNeeded()
		
		UIView.animate(withDuration: 0.2, delay: 0.0, options: .curveEaseInOut,
					   animations: {
			self.dimView.alpha = 1.0;
			self.alpha = 1.0;
		},
					   completion: { _ in
			completion?();
		});
	}
}
