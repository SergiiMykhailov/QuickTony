//
//  AppSettings.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/28/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import VisheoVideo


struct AppSettings
{
	private (set) var maxSelectablePhotos: Int = 8;
	private (set) var animationSettings: [AnimationSettings] = [];
}


extension AppSettings: Decodable
{
	private enum CodingKeys: String, CodingKey {
		case selectablePhotos = "selectable_photos"
		case animationSettings = "animation_settings"
	}
	
	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		maxSelectablePhotos = try container.decode(Int.self, forKey: .selectablePhotos);
		animationSettings = try container.decode([AnimationSettings].self, forKey: .animationSettings);
	}
}


extension AnimationSettings: Decodable {
	
	private enum CodingKeys: String, CodingKey {
		case maxAssets = "assets"
		case coverAnimationDuration = "cover_duration"
		case assetAnimationDuration = "asset_duration"
	}
	
	public init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		let defaultDuration: TimeInterval = 2.2;
		
		maxAssets = try container.decode(Int.self, forKey: .maxAssets);
		coverAnimationDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .coverAnimationDuration) ?? defaultDuration;
		assetAnimationDuration = try container.decodeIfPresent(TimeInterval.self, forKey: .assetAnimationDuration) ?? defaultDuration;
	}
}
