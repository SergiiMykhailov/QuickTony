//
//  RenderQuality.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/28/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//


import Foundation
import AVFoundation


public enum RenderQuality: Int
{
	case res720 = 720
	case res1080 = 1080
}


extension RenderQuality
{
	var renderSize: CGSize {
		return CGSize(width: rawValue, height: rawValue);
	}
	
	
	static var maxRenderSize: CGSize {
		return CGSize(width: RenderQuality.res1080.rawValue, height: RenderQuality.res1080.rawValue);
	}
}


extension RenderQuality {
	
	var exportSessionPreset: String
	{
		switch self
		{
			case .res720:
				return AVAssetExportPreset640x480;
			case .res720:
				return AVAssetExportPreset1280x720;
			case .res1080:
				return AVAssetExportPreset1920x1080;
		}
	}
}
