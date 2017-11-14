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


protocol VideoConvertible
{
	func render(to url: URL, on queue: DispatchQueue?, completion: @escaping (Result<Void>) -> Void)
}


extension VideoConvertible
{
	func willBeginRender() {}
	func didBeginRender() {}
}


final class VideoConvertibleRenderer
{
	private let queue = DispatchQueue(label: "com.visheo.convertible.queue", qos: .default, attributes: .concurrent);
	
	public init(){}
	
	
	public func render(asset: VideoConvertible, to url: URL, completion: @escaping (Result<Void>) -> Void)
	{
		asset.render(to: url, on: queue, completion: completion);
	}
}
