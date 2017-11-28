//
//  PhotosAnimation.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/23/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation


public typealias AssetRepresentation = (url: URL, type: MediaType)


public final class PhotosAnimation: VideoConvertible
{
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	private let frames: [AssetRepresentation];
	private let quality: RenderQuality;
	private let settings: AnimationSettings;
	
	private let containerLayer = CALayer();
	
	
	public init(frames: [AssetRepresentation], quality: RenderQuality, settings: AnimationSettings)
	{
		self.frames = frames;
		self.quality = quality;
		self.settings = settings;
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
		let renderSize = quality.renderSize;
		
		let renderFrame = CGRect(origin: .zero, size: renderSize);
		containerLayer.frame = renderFrame;
		containerLayer.backgroundColor = UIColor.clear.cgColor;
		
		var beginTime = AVCoreAnimationBeginTimeAtZero;
		var duration = 0.0;
		
		for (index, asset) in frames.enumerated()
		{
			let image = UIImage(contentsOfFile: asset.url.path)!.fixedOrientation();
			
			let scaledSize = image.scaledSize(fitting: renderSize);
			
			let motion = Motion.motionForAsset(sized: scaledSize, inBounds: renderSize);
			let offset = motion.initialOffset(for: scaledSize, inBounds: renderSize);
			
			let contentsLayer = CALayer();
			
			contentsLayer.contents = image.cgImage;
			contentsLayer.frame = CGRect(origin: .zero, size: scaledSize);
			contentsLayer.position = CGPoint(x: renderFrame.midX, y: renderFrame.midY);
			contentsLayer.backgroundColor = UIColor.clear.cgColor;
			contentsLayer.opacity = (index > 0) ? 0.0 : 1.0;
			
			containerLayer.insertSublayer(contentsLayer, at: 0);
			
			let transitionAnimationDuration = 2.2;
			
			if asset.type == .photo || asset.type == .video
			{
				let fadeInAnimation = CAKeyframeAnimation(keyPath: "opacity");
				fadeInAnimation.beginTime = beginTime;
				fadeInAnimation.values = [ 1.0, 1.0, 0.0, 0.0 ];
				fadeInAnimation.keyTimes = [ 0.0, 0.4, 0.6, 1.0 ];
				fadeInAnimation.duration = transitionAnimationDuration;
				fadeInAnimation.isRemovedOnCompletion = false;
				fadeInAnimation.fillMode = kCAFillModeBoth;
				
				contentsLayer.add(fadeInAnimation, forKey: "fade_in");
				
				let animDuration = fadeInAnimation.duration * 0.45;
				
				beginTime += animDuration;
				duration += animDuration;
			}
			
			if asset.type == .cover || asset.type == .photo
			{
				let motionAnimation = animation(for: motion, in: contentsLayer, initialOffset: offset);
				motionAnimation.beginTime = beginTime;
				
				switch asset.type {
					case .photo:
						motionAnimation.duration = settings.assetAnimationDuration;
					case .cover:
						motionAnimation.duration = settings.coverAnimationDuration;
					default:
						break;
				}
			
				contentsLayer.add(motionAnimation, forKey: "motion");
				
				let animDuration = (motionAnimation.duration - 0.55 * transitionAnimationDuration);
				
				beginTime += animDuration;
				duration += animDuration;
				
				let fadeOutAnimation = CAKeyframeAnimation(keyPath: "opacity");
				fadeOutAnimation.beginTime = beginTime;
				fadeOutAnimation.values = [ 1.0, 1.0, 0.0, 0.0 ];
				fadeOutAnimation.keyTimes = [ 0.0, 0.4, 0.6, 1.0 ];
				fadeOutAnimation.duration = transitionAnimationDuration;
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
		
		let renderSize = quality.renderSize;
		
		let frame = CGRect(origin: CGPoint.zero, size: renderSize);
		
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
		
		videoComposition.renderSize = renderSize;
		videoComposition.instructions = [mainInstruction];
		videoComposition.frameDuration = CMTimeMake(1, 30);
		videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer);
		
		guard let session = AVAssetExportSession(asset: composition, presetName: quality.exportSessionPreset) else {
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
