//
//  LottieFrameTransition.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/21/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Lottie
import AVFoundation


class LottieFrameTransition: VideoConvertible
{
	private let animation: URL;
	private let size: CGSize;
	private let frames: [URL];
	private let container: LOTCompositionContainer;
	private let composition: LOTComposition;
	private var writer: AVAssetWriter?;
	private var input: AVAssetWriterInput?;
	private var adaptor: AVAssetWriterInputPixelBufferAdaptor?;
	
	
	public init(animation: URL, size: CGSize, frames: [URL])
	{
		self.animation = animation;
		self.size = CGSize(width: size.width, height: size.height);
		self.frames = frames;
		
		let assets = [ "image_1" : frames[0].path, "image_0" : frames[1].path ]
		let composition = LOTComposition(filePath: animation.path, assetPaths: assets);
		
		self.composition = composition!;
		
		container = LOTCompositionContainer(model: nil, in: nil, with: composition?.layerGroup, withAssestGroup: composition?.assetGroup);
		container.bounds = composition!.compBounds
		container.isGeometryFlipped = true;
		
		let scale = size.width / composition!.compBounds.width;
		container.setAffineTransform(CGAffineTransform(scaleX: scale, y: scale));
	}
	
	
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	
	func produceFrame(i: Int, options: [String : Any]) -> CVPixelBuffer?
	{
		container.display(withFrame: NSNumber(value: i));
		
		var pxbuffer: CVPixelBuffer? = nil
				
		CVPixelBufferCreate(kCFAllocatorDefault, Int(size.width), Int(size.height), kCVPixelFormatType_32ARGB, options as CFDictionary, &pxbuffer);
				
		guard let buffer = pxbuffer else {
			return nil;
		}
				
		CVPixelBufferLockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
				
		guard let pxdata = CVPixelBufferGetBaseAddress(buffer) else {
			return nil;
		}
				
		let bytesPerRow = CVPixelBufferGetBytesPerRow(buffer)
				
		let space = CGColorSpaceCreateDeviceRGB()
		let context = CGContext(data: pxdata, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: space, bitmapInfo: CGImageAlphaInfo.noneSkipFirst.rawValue);
		
		context?.concatenate(container.affineTransform())
		container.render(in: context!);
				
		CVPixelBufferUnlockBaseAddress(buffer, CVPixelBufferLockFlags(rawValue: 0))
			
		return buffer;
	}
	
	
	func render(to url: URL, on queue: DispatchQueue?, completion: @escaping (Result<Void>) -> Void)
	{
		let adap = [ String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32ARGB ];
		let out : [String : Any ] = [ AVVideoCodecKey : AVVideoCodecJPEG,
									  AVVideoWidthKey : size.width,
									  AVVideoHeightKey: size.height ]
		
		input = AVAssetWriterInput(mediaType: .video, outputSettings: out);
		adaptor = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input!, sourcePixelBufferAttributes: adap);
		writer = try! AVAssetWriter(url: url, fileType: .mp4);
		writer?.add(input!);
		
		writer?.startWriting();
		writer?.startSession(atSourceTime: kCMTimeZero);
		
		let options = [ String(kCVPixelBufferCGImageCompatibilityKey): true,
						String(kCVPixelBufferCGBitmapContextCompatibilityKey): true]
		
		var i = (composition.startFrame?.intValue)!;
		let endFrame = (composition.endFrame?.intValue)!;
		
		input?.requestMediaDataWhenReady(on: DispatchQueue.global(), using: { [weak self] in
			guard let me = self, let input = me.input else {
				return;
			}
			
			while input.isReadyForMoreMediaData
			{
				if i > endFrame {
					input.markAsFinished();
					me.writer?.finishWriting {
						completion(.success(value: Void()));
					}
				} else {
					autoreleasepool {
						let buffer = me.produceFrame(i: i, options: options)!;
						me.adaptor?.append(buffer, withPresentationTime: CMTime(value: CMTimeValue(i), timescale: 30));
						i = i + 1;
					}
				}
			}
		});
	}
}
