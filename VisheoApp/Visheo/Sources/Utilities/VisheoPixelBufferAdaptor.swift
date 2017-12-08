//
//  VisheoPixelBufferAdaptor.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation

class VisheoPixelBufferAdaptor: AVAssetWriterInputPixelBufferAdaptor
{
	var didAppendSampleBuffer: (() -> Void)?;
	
	override func append(_ pixelBuffer: CVPixelBuffer, withPresentationTime presentationTime: CMTime) -> Bool {
		let result = super.append(pixelBuffer, withPresentationTime: presentationTime);
		defer {
			if (result) {
				didAppendSampleBuffer?();
			}
		}
		return result;
	}
}
