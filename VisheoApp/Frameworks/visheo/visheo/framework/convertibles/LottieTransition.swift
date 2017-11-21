//
//  LottieTransition.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Lottie
import AVFoundation
import pop


public final class LottieTransition: VideoConvertible
{
    private let animation: URL;
    private let size: CGSize;
    private let frames: [URL];
	private var animationContainer: LOTAnimationView?;
	
	
    public init(animation: URL, size: CGSize, frames: [URL])
    {
        self.animation = animation;
        self.size = CGSize(width: size.width, height: size.height);
        self.frames = frames;
    }
	
	
	deinit {
		print("I'm dead");
	}
	
	
	var renderQueueSupport: ProcessingQueueType {
		return .serial;
	}
	
    
	func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
    {
		createAnimationContainer(animation: animation, size: size, frames: frames) { [weak self] (container) in
			
			self?.animationContainer = container;
			
			guard let `self` = self else { return }
			
			let path = Bundle.main.path(forResource: "blank", ofType: "m4v")!;
			let blankURL = URL.init(fileURLWithPath: path);
			
			let asset = AVURLAsset(url: blankURL);
			
			let videoTrack = asset.tracks(withMediaType: .video).first!;
			
			let composition = AVMutableComposition();
			
			guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
				completion(.failure(error: VideoConvertibleError.error));
				return;
			}
			
			let duration = CMTimeMakeWithSeconds(Float64(container.animationDuration), asset.duration.timescale);
			let range = CMTimeRangeMake(kCMTimeZero, duration);
			
			try? track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), of: videoTrack, at: kCMTimeZero);
			
			let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track);
			
			let mainInstruction = AVMutableVideoCompositionInstruction();
			mainInstruction.layerInstructions = [trackInstruction];
			mainInstruction.timeRange = range;
			
			let frame = CGRect(origin: CGPoint.zero, size: self.size);
			
			let parentLayer = CALayer();
			let videoLayer = CALayer();
			
			parentLayer.frame = frame;
			videoLayer.frame = frame;
			
			parentLayer.addSublayer(videoLayer);
			parentLayer.addSublayer(container.layer);
			
			let animation = POPBasicAnimation(customPropertyNamed: "prop", read: { (obj, values) in
				if let v = obj as? LOTAnimationView, let vls = values {
					vls[0] = v.currentFrameHandle;
				}
			}) { (obj, values) in
				if let v = obj as? LOTAnimationView, let vls = values {
					v.currentFrameHandle = vls[0];
				}
			}
			
			animation?.duration = CFTimeInterval(container.animationDuration);
			animation?.fromValue = container.sceneModel?.startFrame;
			animation?.toValue = container.sceneModel?.endFrame;
			animation?.beginTime = AVCoreAnimationBeginTimeAtZero;
			animation?.removedOnCompletion = false;
			animation?.repeatCount = 0;
			
			container.pop_add(animation, forKey: url.lastPathComponent);
			
			let videoComposition = AVMutableVideoComposition();
			
			//		let width = round(self.size.width / 16.0) * 16.0;
			//		let height = round(self.size.height * (self.size.width / width))
			
			videoComposition.renderSize = self.size;//CGSize(width: width, height: height);
			videoComposition.instructions = [mainInstruction];
			videoComposition.frameDuration = CMTimeMake(1, container.sceneModel?.framerate?.int32Value ?? 30);
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
    }
	
	
	private func createAnimationContainer(animation: URL, size: CGSize, frames: [URL], _ completion: @escaping (LOTAnimationView) -> Void)
	{
		DispatchQueue.main.async
		{
			let frame = CGRect(origin: CGPoint.zero, size: size);
			
			let assets = [ "image_0" : frames[0].path, "image_1" : frames[1].path ]
			let composition = LOTComposition(filePath: animation.path, assetPaths: assets);
			
			let animationContainerView = LOTAnimationView(model: composition, in: nil);
			animationContainerView.frame = frame;
			animationContainerView.contentMode = .scaleAspectFill;
			animationContainerView.loopAnimation = false;
			
			DispatchQueue.global().async {
				completion(animationContainerView);
			}
		}
	}
}
