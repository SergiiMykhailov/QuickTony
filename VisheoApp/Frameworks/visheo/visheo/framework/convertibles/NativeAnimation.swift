//
//  MotionAnimation.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation
import UIKit.UIImage


final class NativeAnimation: VideoConvertible
{
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	private let frames: [URL];
	private let duration: TimeInterval;
	private let size: CGSize;
	
	
	init(frames: [URL], size: CGSize, duration: TimeInterval)
	{
		self.frames = frames;
		self.duration = duration;
		self.size = size;
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
		
		let duration = CMTimeMakeWithSeconds(self.duration, 600);
		let range = CMTimeRangeMake(kCMTimeZero, duration);
		
		try? track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), of: videoTrack, at: kCMTimeZero);
		
		let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track);
		
		let mainInstruction = AVMutableVideoCompositionInstruction();
		mainInstruction.layerInstructions = [trackInstruction];
		mainInstruction.timeRange = range;
		
		let transitionLayer = TransitionContainer(size: size);
		
		let image1 = UIImage(contentsOfFile: frames[0].path)!
		let image2 = UIImage(contentsOfFile: frames[1].path)!;
		
		transitionLayer.set(contents: image1, for: .from);
		transitionLayer.set(contents: image2, for: .to);
		
		
		let animFrom = CAKeyframeAnimation(keyPath: "opacity");
		animFrom.duration = self.duration;
		animFrom.keyTimes = [ 0.0, 0.40, 0.60, 1.0 ];
		animFrom.values = [ 1.0, 1.0, 0.0, 0.0 ];
		animFrom.beginTime = AVCoreAnimationBeginTimeAtZero;
		animFrom.isRemovedOnCompletion = false;
		
		let animTo = CAKeyframeAnimation(keyPath: "opacity");
		animTo.duration = self.duration;
		animTo.keyTimes = [ 0.0, 0.40, 0.60, 1.0 ];
		animTo.values = [ 0.0, 0.0, 1.0, 1.0 ];
		animTo.beginTime = AVCoreAnimationBeginTimeAtZero;
		animTo.isRemovedOnCompletion = false;
		
		transitionLayer.animate(with: [ .from : animFrom, .to : animTo ]);
		
		
		let parentLayer = CALayer();
		let videoLayer = CALayer();
		
		parentLayer.frame = frame;
		videoLayer.frame = frame;
		
		parentLayer.addSublayer(videoLayer);
		parentLayer.addSublayer(transitionLayer.animatableLayer);
		
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
