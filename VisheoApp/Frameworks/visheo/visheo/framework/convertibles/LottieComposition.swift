//
//  LottieComposition.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/13/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation


class LottieComposition: NSObject, AVVideoCompositing
{
	override init() {
		super.init();
	}
	
	var sourcePixelBufferAttributes: [String : Any]? {
		return [ String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA,
		          String(kCVPixelBufferOpenGLESCompatibilityKey) : true ];
	}
	
	
	var requiredPixelBufferAttributesForRenderContext: [String : Any] {
		return [  String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32BGRA,
		          String(kCVPixelBufferOpenGLESCompatibilityKey) : true ];
	}
	
	
	func renderContextChanged(_ newRenderContext: AVVideoCompositionRenderContext)
	{
		
	}
	
	
	func startRequest(_ request: AVAsynchronousVideoCompositionRequest)
	{
		autoreleasepool
		{
			let time = request.compositionTime;
			let tracks = request.sourceTrackIDs;
			
			print("\(time) \(tracks)");
			
			if (tracks.count > 0)
			{
				let buff1 = request.sourceFrame(byTrackID: tracks.first!.int32Value)
				let buff2 = request.sourceFrame(byTrackID: tracks.last!.int32Value);
				
				request.finish(withComposedVideoFrame: buff1!);
				return;
			}
			
			let buf = request.renderContext.newPixelBuffer();
			request.finish(withComposedVideoFrame: buf!);
			return;
		}
	}
	

}
