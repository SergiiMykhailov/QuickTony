//
//  Container.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/23/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation


enum Motion
{
	case left
	case right
	case top
	case bottom
	case zoom
}


extension Motion
{
	static func motionForAsset(sized assetSize: CGSize, inBounds boundingSize: CGSize) -> Motion
	{
		if assetSize.isLessOrClose(to: boundingSize) {
			return .zoom;
		}
		
		let side = arc4random_uniform(2);
		
		if (assetSize.width > assetSize.height) {
			return side > 0 ? .left : .right;
		}
		
		if (assetSize.height > boundingSize.height) {
			return side > 0 ? .top : .bottom;
		}
		
		return .zoom;
	}
	
	
	func initialOffset(for assetSize: CGSize, inBounds boundingSize: CGSize) -> CGPoint
	{
		let horizontalOffset = (assetSize.width - boundingSize.width) / 2.0;
		let verticalOffset = (assetSize.height - boundingSize.height) / 2.0;
		
		var point = CGPoint.zero;
		
		switch self
		{
		case .zoom:
			return point;
		case .left:
			point.x = -horizontalOffset / 2.0;
		case .right:
			point.x = horizontalOffset / 2.0;
		case .top:
			point.y = -verticalOffset / 2.0;
		case .bottom:
			point.y = verticalOffset / 2.0;
		}
		
		return point;
	}
}


extension CGSize
{
	func isLessOrClose(to other: CGSize, threshold: CGFloat = 3.0) -> Bool
	{
		if width < other.width && height < other.height {
			return true;
		}
		
		return fabs(width - height) < threshold &&
			fabs(width - other.width) < threshold &&
			fabs(height - other.height) < threshold;
	}
}



public final class Container: VideoConvertible
{
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	private let frames: [URL];
	private let size: CGSize;
	
	private let containerLayer = CALayer();
	
	
	public init(frames: [URL], size: CGSize)
	{
		self.frames = frames;
		self.size = size;
	}
	
	
	func animation(for motion: Motion, in layer: CALayer, initialOffset offset: CGPoint) -> CABasicAnimation
	{
		var animation: CABasicAnimation;
		
		if case .zoom = motion {
			animation = CABasicAnimation(keyPath: "transform.scale");
			animation.fromValue = 1.0;
			animation.toValue = 1.2;
		}
		else {
			var position = layer.position;
			position.x += offset.x;
			position.y += offset.y;
			
			var finalPosition = layer.position;
			finalPosition.x -= offset.x;
			finalPosition.y -= offset.y;
			
			animation = CABasicAnimation(keyPath: "position");
			animation.fromValue = position;
			animation.toValue = finalPosition;
		}
		
		animation.isRemovedOnCompletion = false;
		animation.fillMode = kCAFillModeBoth;
		
		return animation;
	}
	
	
	func prepare() -> (layer: CALayer, duration: TimeInterval)
	{
		let frame = CGRect(origin: .zero, size: size);
		containerLayer.frame = frame;
		containerLayer.backgroundColor = UIColor.clear.cgColor;
		
		var beginTime = AVCoreAnimationBeginTimeAtZero;
		var duration = 0.0;
		
		for (index, url) in frames.enumerated()
		{
			let image = UIImage(contentsOfFile: url.path)!.fixedOrientation();
			
			let scaledSize = image.scaledSize(fitting: size);
			
			let motion = Motion.motionForAsset(sized: scaledSize, inBounds: size);
			let offset = motion.initialOffset(for: scaledSize, inBounds: size);
			
			let contentsLayer = CALayer();
			
			contentsLayer.contents = image.cgImage;
			contentsLayer.frame = CGRect(origin: .zero, size: scaledSize);
			contentsLayer.position = CGPoint(x: frame.midX, y: frame.midY);
			contentsLayer.backgroundColor = UIColor.clear.cgColor;
			contentsLayer.opacity = (index > 0) ? 0.0 : 1.0;
			
			
			
			containerLayer.insertSublayer(contentsLayer, at: 0);
			
			if (index > 0)
			{
				let fadeInAnimation = CAKeyframeAnimation(keyPath: "opacity");
				fadeInAnimation.beginTime = beginTime;
				fadeInAnimation.values = [ 1.0, 1.0, 0.0, 0.0 ];
				fadeInAnimation.keyTimes = [ 0.0, 0.4, 0.6, 1.0 ];
				fadeInAnimation.duration = 2.2;
				fadeInAnimation.isRemovedOnCompletion = false;
				fadeInAnimation.fillMode = kCAFillModeBoth;
				
				contentsLayer.add(fadeInAnimation, forKey: "fade_in");
				
				let animDuration = fadeInAnimation.duration * 0.45;
				
				beginTime += animDuration;
				duration += animDuration;
			}
			
			if index < frames.count - 1
			{
				let motionAnimation = animation(for: motion, in: contentsLayer, initialOffset: offset);
				motionAnimation.beginTime = beginTime;
				motionAnimation.duration = 2.2;
				
				contentsLayer.add(motionAnimation, forKey: "motion");
				
				let animDuration = motionAnimation.duration * 0.45;
				
				beginTime += animDuration;
				duration += animDuration;
				
				let fadeOutAnimation = CAKeyframeAnimation(keyPath: "opacity");
				fadeOutAnimation.beginTime = beginTime;
				fadeOutAnimation.values = [ 1.0, 1.0, 0.0, 0.0 ];
				fadeOutAnimation.keyTimes = [ 0.0, 0.4, 0.6, 1.0 ];
				fadeOutAnimation.duration = 2.2;
				fadeOutAnimation.isRemovedOnCompletion = false;
				fadeOutAnimation.fillMode = kCAFillModeBoth;
				
				contentsLayer.add(fadeOutAnimation, forKey: "fade_out");
			}
		}
		
		return (containerLayer, duration);
	}
	
	
	public func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
	{
		let start = CACurrentMediaTime();
		print("Start rendering transition \(url.lastPathComponent)")
		
		let frame = CGRect(origin: CGPoint.zero, size: size);
		
		let path = Bundle.main.path(forResource: "blank", ofType: "m4v")!;
		let blankURL = URL.init(fileURLWithPath: path);
		
		let asset = AVURLAsset(url: blankURL);
		
		let videoTrack = asset.tracks(withMediaType: .video).first!;
		
		let composition = AVMutableComposition();
		
		guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			completion(.failure(error: VideoConvertibleError.error));
			return;
		}
		
		let animation = prepare()
		
		let duration = CMTimeMakeWithSeconds(animation.duration, 600);
		let range = CMTimeRangeMake(kCMTimeZero, duration);
		
		try? track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), of: videoTrack, at: kCMTimeZero);
		
		let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track);
		
		let mainInstruction = AVMutableVideoCompositionInstruction();
		mainInstruction.layerInstructions = [trackInstruction];
		mainInstruction.timeRange = range;
		
		let parentLayer = CALayer();
		let videoLayer = CALayer();
		
		parentLayer.frame = frame;
		videoLayer.frame = frame;
		
		parentLayer.addSublayer(videoLayer);
		parentLayer.addSublayer(animation.layer);
		
		let videoComposition = AVMutableVideoComposition();
		
		videoComposition.renderSize = size;
		videoComposition.instructions = [mainInstruction];
		videoComposition.frameDuration = CMTimeMake(1, 30);
		videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer);
		
		guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset640x480) else {
			completion(.failure(error: VideoConvertibleError.error));
			return;
		}
		
		session.outputURL = url;
		session.outputFileType = .mp4;
		//		session.shouldOptimizeForNetworkUse = true;
		session.videoComposition = videoComposition;
		session.timeRange = range;
		
		session.exportAsynchronously
			{
				print("Finished rendering transition \(url.lastPathComponent) in \(CACurrentMediaTime() - start)")
				
				if let e = session.error {
					completion(.failure(error: e));
				} else {
					completion(.success(value: Void()))
				}
		}
	}
}
