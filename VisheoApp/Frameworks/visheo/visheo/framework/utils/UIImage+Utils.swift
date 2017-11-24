//
//  UIImage+Utils.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/13/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import UIKit

extension UIImage
{
	var pixelBuffer: CVPixelBuffer?
	{
		guard let imgRef = self.cgImage else {
			return nil;
		}
		
		let size = self.size;
		
		let options = [ kCVPixelBufferCGImageCompatibilityKey : true,
		                kCVPixelBufferCGBitmapContextCompatibilityKey : true
		]
		
		var buffer: CVPixelBuffer? = nil;
		
		let status = CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &buffer);
		
		guard status == kCVReturnSuccess, let buf = buffer else {
			return nil;
		}
		
		CVPixelBufferLockBaseAddress(buf, CVPixelBufferLockFlags(rawValue: 0));
		
		let pxData = CVPixelBufferGetBaseAddress(buf);
		
		let colorSpace = CGColorSpaceCreateDeviceRGB();
		
		let context = CGContext.init(data: pxData, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: 4 * Int(size.width), space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue)
		
		context?.draw(imgRef, in: CGRect(origin: .zero, size: size));
		
		CVPixelBufferUnlockBaseAddress(buf, CVPixelBufferLockFlags(rawValue: 0))
		
		return buf;
	}
	
	
	func scaledSize(fitting fittingSize: CGSize) -> CGSize
	{
		var scaledSize = self.size;
		
		let horizontalScale = fittingSize.width / size.width;
		let verticalScale = fittingSize.height / size.height;
		
		let scale = fmax(horizontalScale, verticalScale);
		
		scaledSize.width *= scale;
		scaledSize.height *= scale;
		
		return scaledSize;
	}
}
