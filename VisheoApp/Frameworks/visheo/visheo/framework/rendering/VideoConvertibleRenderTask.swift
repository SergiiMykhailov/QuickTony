//
//  VideoRenderInfo.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//


import AVFoundation

public struct VideoConvertibleRenderTask
{
	public let mainComposition: AVComposition;
	public let videoComposition: AVVideoComposition;
	public let timeRange: CMTimeRange;
	
	init(main: AVComposition, video: AVVideoComposition, range: CMTimeRange)
	{
		self.mainComposition = main;
		self.videoComposition = video;
		self.timeRange = range;
	}
}
