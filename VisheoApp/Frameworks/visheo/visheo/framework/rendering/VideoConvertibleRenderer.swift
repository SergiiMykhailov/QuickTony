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
	func prepareForRender(_ completion: @escaping (Result<VideoConvertibleRenderTask>) -> Void)
	func willBeginRender()
	func didBeginRender()
}


extension VideoConvertible
{
	func willBeginRender() {}
	func didBeginRender() {}
}


final class VideoConvertibleRenderer
{
	private var asset: VideoConvertible? = nil;
	
	
	public init(){}
	
	
	public func render(asset: VideoConvertible, to url: URL, completion: @escaping (Result<Void>) -> Void)
	{
		DispatchQueue.main.async {
			asset.prepareForRender { (result) in
				
				if case .failure(let error) = result {
					completion(.failure(error: error));
					return;
				}
				
				guard let task = result.value, let session = AVAssetExportSession(asset: task.mainComposition, presetName: AVAssetExportPresetHighestQuality) else {
					completion(.failure(error: VideoConvertibleError.error));
					return;
				}
				
				session.outputURL = url;
				session.outputFileType = .mp4;
				session.shouldOptimizeForNetworkUse = true;
				session.videoComposition = task.videoComposition;
				session.timeRange = task.timeRange;
				
				asset.willBeginRender()
				
				session.exportAsynchronously
				{
					if let e = session.error {
						completion(.failure(error: e));
					} else {
						completion(.success(value: Void()))
					}
					print("\(String(describing: session.error))")
				}
				
				asset.didBeginRender();
			}
		}
		
		
	}
}
