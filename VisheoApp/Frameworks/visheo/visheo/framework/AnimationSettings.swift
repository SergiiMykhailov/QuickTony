//
//  AnimationSettings.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/28/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//


public struct AnimationSettings
{
	public let maxAssets: Int;
	public let coverAnimationDuration: TimeInterval;
	public let assetAnimationDuration: TimeInterval;
	
	
	public init(assets: Int = 0, coverDuration: TimeInterval = 2.2, assetDuration: TimeInterval = 2.2)
	{
		self.maxAssets = assets;
		self.coverAnimationDuration = coverDuration;
		self.assetAnimationDuration = assetDuration;
	}
}


public extension Sequence where Element == AnimationSettings
{
	public func withAssetsCount(_ count: Int) -> Element? {
		return filter{ count >= $0.maxAssets }.last
	}
}
