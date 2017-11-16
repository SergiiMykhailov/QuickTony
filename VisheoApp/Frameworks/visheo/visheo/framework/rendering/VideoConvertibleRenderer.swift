//
//  VideoConverterFactory.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation


enum VideoConvertibleError: Error
{
	case error
}


enum ProcessingQueueType
{
	case main
	case serial
	case concurrent
}


protocol VideoConvertible
{
	var renderQueueSupport: ProcessingQueueType { get }
	
	func render(to url: URL, on queue: DispatchQueue?, completion: @escaping (Result<Void>) -> Void)
}


extension VideoConvertible
{
	func willBeginRender() {}
	func didBeginRender() {}
}


final class VideoConvertibleRenderer
{
	private let concurrentQueue = OperationQueue();
	private let serialQueue = OperationQueue()
	
	public init()
	{
		serialQueue.maxConcurrentOperationCount = 1;
	}
	
	
	public func render(asset: VideoConvertible, to url: URL, completion: @escaping (Result<Void>) -> Void) -> Operation
	{
		let operation = VideoConvertibleRenderOperation(asset: asset, url: url);
		
		operation.completion = completion;
		
		switch asset.renderQueueSupport
		{
			case .concurrent:
				concurrentQueue.addOperation(operation);
			case .serial:
				serialQueue.addOperation(operation);
			case .main:
				OperationQueue.main.addOperation(operation);
		}
		
		return operation;
	}
}
