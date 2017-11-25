//
//  MotionAnimation.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation
import UIKit.UIImage


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


final class MotionAnimation: VideoConvertible
{
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	typealias MotionLayer = (parent: CALayer, animatable: CALayer, animation: CABasicAnimation);
	
	
	private let asset: URL;
	private let duration: TimeInterval;
	private let bounds: CGSize;
	
	
	private lazy var motionLayer: MotionLayer = prepareMotionLayer();
	
	
	init(asset: URL, bounds: CGSize, duration: TimeInterval)
	{
		self.asset = asset;
		self.duration = duration;
		self.bounds = bounds;
	}
	
	
	func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
	{
		let start = CACurrentMediaTime();
		print("Start rendering motion \(url.lastPathComponent)")
		
		let frame = CGRect(origin: CGPoint.zero, size: self.bounds);
			
		let path = Bundle.main.path(forResource: "blank", ofType: "m4v")!;
		let blankURL = URL.init(fileURLWithPath: path);
		
		let asset = AVURLAsset(url: blankURL);
		
		let videoTrack = asset.tracks(withMediaType: .video).first!;
		
		let composition = AVMutableComposition();
		
		guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
			completion(.failure(error: VideoConvertibleError.error));
			return;
		}
		
		let duration = CMTimeMakeWithSeconds(self.duration, 600);
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
		parentLayer.addSublayer(self.motionLayer.parent);
		
		let videoComposition = AVMutableVideoComposition();
		
//		let width = round(self.bounds.width / 16.0) * 16.0;
//		let height = round(self.bounds.height * (self.bounds.width / width))
		
		videoComposition.renderSize = bounds;//CGSize(width: width, height: height);
		videoComposition.instructions = [mainInstruction];
		videoComposition.frameDuration = CMTimeMake(1, 30);
		videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer);
		
		guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset640x480) else {
			completion(.failure(error: VideoConvertibleError.error));
			return;
		}
		
		session.outputURL = url;
		session.outputFileType = .mp4;
		session.shouldOptimizeForNetworkUse = true;
		session.videoComposition = videoComposition;
		session.timeRange = range;

		session.exportAsynchronously
		{
			print("Finished rendering motion \(url.lastPathComponent) in \(CACurrentMediaTime() - start)")
			
			if let e = session.error {
				completion(.failure(error: e));
			} else {
				completion(.success(value: Void()))
			}
		}
	}
	
	
	public func prepareMotionLayer() -> MotionLayer
	{
		let image = UIImage(contentsOfFile: asset.path)!;
		
		let assetSize = image.scaledSize(fitting: bounds)
		
		let motion = Motion.motionForAsset(sized: assetSize, inBounds: bounds);
		
		let offset = motion.initialOffset(for: assetSize, inBounds: bounds);
		
		let parentLayer = CALayer();
		parentLayer.frame = CGRect(origin: CGPoint.zero, size: bounds);
		parentLayer.backgroundColor = UIColor.red.cgColor;
		parentLayer.masksToBounds = true;
		
		let assetLayer = CALayer();
		assetLayer.contents = image.cgImage;
		assetLayer.frame = CGRect(origin: CGPoint.zero, size: assetSize);
		assetLayer.backgroundColor = UIColor.green.cgColor;
		assetLayer.masksToBounds = false;
		assetLayer.position = CGPoint(x: bounds.width / 2.0, y: bounds.height / 2.0);
		
		var position = assetLayer.position;
		position.x += offset.x;
		position.y += offset.y;
		
		var finalPosition = assetLayer.position;
		finalPosition.x -= offset.x;
		finalPosition.y -= offset.y;
		
		parentLayer.addSublayer(assetLayer);
		
		let animation = CABasicAnimation(keyPath: "position");
		
		animation.fromValue = NSValue.init(cgPoint: position);
		animation.toValue = NSValue.init(cgPoint: finalPosition);
		animation.duration = duration;
		animation.isRemovedOnCompletion = false;
		animation.repeatCount = 1;
		animation.beginTime = AVCoreAnimationBeginTimeAtZero;
		
		assetLayer.add(animation, forKey: "animation");
		
		return (parentLayer, assetLayer, animation);
	}
}
