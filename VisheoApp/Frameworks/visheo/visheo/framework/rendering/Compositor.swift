//
//  Compositor.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/7/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation

class Compositor: NSObject, AVVideoCompositing
{
	func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext)
	{
		
	}
	
	var sourcePixelBufferAttributes: [String : Any]? {
		return [ String(kCVPixelBufferPixelFormatTypeKey) : [ kCVPixelFormatType_32RGBA ] ]
	}
	
	var requiredPixelBufferAttributesForRenderContext: [String : Any] {
		return [ String(kCVPixelBufferPixelFormatTypeKey) : [ kCVPixelFormatType_32RGBA ] ]
	}
	
	
	func startRequest(_ request: AVAsynchronousVideoCompositionRequest)
	{
		let ids = request.sourceTrackIDs;
		
		let buffer = request.sourceFrame(byTrackID: ids[0].int32Value)!;
		
		request.finish(withComposedVideoFrame: buffer);
	}
	
	

}
