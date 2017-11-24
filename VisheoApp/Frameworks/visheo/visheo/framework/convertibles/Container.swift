//
//  Container.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/23/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation


class Container: VideoConvertible
{
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	private let frames: [URL];
	private let size: CGSize;
	
	private let containerLayer = CALayer();
	
	
	init(frames: [URL], size: CGSize)
	{
		self.frames = frames;
		self.size = size;
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
			let image = UIImage(contentsOfFile: url.path)!;
			
			let scaledSize = image.scaledSize(fitting: size);
			
			let motion = Motion.motionForAsset(sized: scaledSize, inBounds: size);
			let offset = motion.initialOffset(for: scaledSize, inBounds: size);
			
			let contentsLayer = CALayer();
			
			contentsLayer.contents = image.cgImage;
			contentsLayer.frame = CGRect(origin: .zero, size: scaledSize);
			contentsLayer.position = CGPoint(x: frame.midX, y: frame.midY);
			contentsLayer.backgroundColor = UIColor.clear.cgColor;
			contentsLayer.opacity = (index > 0) ? 0.0 : 1.0;
			
			var position = contentsLayer.position;
			position.x += offset.x;
			position.y += offset.y;
			
			var finalPosition = contentsLayer.position;
			finalPosition.x -= offset.x;
			finalPosition.y -= offset.y;
			
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
				
				let animDuration = fadeInAnimation.duration * 0.55;
				
				beginTime += animDuration;
				duration += animDuration;
			}
			
			if index < frames.count - 1
			{
				let motionAnimation = CABasicAnimation(keyPath: "position");
				motionAnimation.beginTime = beginTime;
				motionAnimation.duration = 2.2;
				motionAnimation.fromValue = position;
				motionAnimation.toValue = finalPosition;
				motionAnimation.isRemovedOnCompletion = false;
				motionAnimation.fillMode = kCAFillModeBoth;
				
				contentsLayer.add(motionAnimation, forKey: "motion");
				
				let animDuration = motionAnimation.duration * 0.55;
				
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
	
	
	func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
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
		
//		let transitionLayer = TransitionContainer(size: size);
//
//		let image1 = UIImage(contentsOfFile: frames[0].path)!
//		let image2 = UIImage(contentsOfFile: frames[1].path)!;
//
//		transitionLayer.set(contents: image1, for: .from);
//		transitionLayer.set(contents: image2, for: .to);
//
//
//		let animFrom = CAKeyframeAnimation(keyPath: "opacity");
//		animFrom.duration = self.duration;
//		animFrom.keyTimes = [ 0.0, 0.40, 0.60, 1.0 ];
//		animFrom.values = [ 1.0, 1.0, 0.0, 0.0 ];
//		animFrom.beginTime = AVCoreAnimationBeginTimeAtZero;
//		animFrom.isRemovedOnCompletion = false;
//
//		let animTo = CAKeyframeAnimation(keyPath: "opacity");
//		animTo.duration = self.duration;
//		animTo.keyTimes = [ 0.0, 0.40, 0.60, 1.0 ];
//		animTo.values = [ 0.0, 0.0, 1.0, 1.0 ];
//		animTo.beginTime = AVCoreAnimationBeginTimeAtZero;
//		animTo.isRemovedOnCompletion = false;
//
//		transitionLayer.animate(with: [ .from : animFrom, .to : animTo ]);
		
		
		let parentLayer = CALayer();
		let videoLayer = CALayer();
		
		parentLayer.frame = frame;
		videoLayer.frame = frame;
		
		parentLayer.addSublayer(videoLayer);
		parentLayer.addSublayer(animation.layer);
		
		let videoComposition = AVMutableVideoComposition();
		
		//		let width = round(self.bounds.width / 16.0) * 16.0;
		//		let height = round(self.bounds.height * (self.bounds.width / width))
		
		videoComposition.renderSize = size;//CGSize(width: width, height: height);
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
