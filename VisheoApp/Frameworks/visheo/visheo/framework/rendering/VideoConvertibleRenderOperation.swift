//
//  VideoConvertibleRenderOperation.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/14/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

class VideoConvertibleRenderOperation: AsyncOperation
{
	private let asset: VideoConvertible;
	private let outputURL: URL;
	var completion: ((Result<Void>) -> Void)?
	
	init(asset: VideoConvertible, url: URL)
	{
		self.asset = asset;
		self.outputURL = url;
		super.init();
	}
	
	
	override func main()
	{
		autoreleasepool
		{
			super.main()
			
			asset.render(to: outputURL, on: nil, completion: { [weak self] (result) in
				self?.completion?(result);
				self?.state = .finished;
			})
		}
	}
}
