//
//  MotionAnimator.swift
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
		if assetSize.isLess(than: boundingSize) {
			return .zoom;
		}
		
		if (assetSize.width > assetSize.height)
		{
			return .left;
		}
		
		if (assetSize.height > boundingSize.height) {
			return .top;
		}
		
		return .left;
	}
}


extension CGSize
{
	func isLess(than other: CGSize) -> Bool
	{
		return width < other.width && height < other.height;
	}
}


final class MotionAnimator: VideoConvertible
{
	typealias MotionLayer = (parent: CALayer, animatable: CALayer, animation: CABasicAnimation);
	
	
	private let asset: UIImage;
	private let duration: TimeInterval;
	private let bounds: CGSize;
	
	
	private lazy var motionLayer: MotionLayer = prepareMotionLayer();
	
	
	init(asset: UIImage, bounds: CGSize, duration: TimeInterval)
	{
		self.asset = asset;
		self.duration = duration;
		self.bounds = bounds;
	}
	
	
	func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
	{
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
		
		guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
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
			if let e = session.error {
				completion(.failure(error: e));
			} else {
				completion(.success(value: Void()))
			}
		}
	}
	
	var scaledAssetSize: CGSize
	{
		var size = asset.size;
		
		let horizontalScale = bounds.width / size.width;
		let verticalScale = bounds.height / size.height;
		
		let scale = fmax(horizontalScale, verticalScale);
		
		size.width *= scale;
		size.height *= scale;
		
		return size;
	}
	
	
	public func prepareMotionLayer() -> MotionLayer
	{
		let assetSize = scaledAssetSize;
		
		let motion = Motion.motionForAsset(sized: assetSize, inBounds: bounds);
		
		let offset = initialOffsetForMotion(motion, assetSize: assetSize, inBounds: bounds);
		
		let parentLayer = CALayer();
		parentLayer.frame = CGRect(origin: CGPoint.zero, size: bounds);
		parentLayer.backgroundColor = UIColor.red.cgColor;
		parentLayer.masksToBounds = true;
		
		let assetLayer = CALayer();
		assetLayer.contents = asset.cgImage;
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
	
	
	private func initialOffsetForMotion(_ motion: Motion, assetSize: CGSize, inBounds boundingSize: CGSize) -> CGPoint
	{
		let horizontalOffset = (assetSize.width - boundingSize.width) / 2.0;
		let verticalOffset = (assetSize.height - boundingSize.height) / 2.0;
		
		var point = CGPoint.zero;
		
		switch motion
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
