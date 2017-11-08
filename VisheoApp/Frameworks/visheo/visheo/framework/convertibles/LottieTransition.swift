//
//  LottieTransition.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Lottie
import AVFoundation


final class LottieTransition: NSObject, VideoConvertible, CALayerDelegate
{
    private let animation: URL;
    private let size: CGSize;
    private let frames: [UIImage];
	private lazy var animationContainer: LOTAnimationView = createAnimationContainer();
    
    init(animation: URL, size: CGSize, frames: [UIImage])
    {
        self.animation = animation;
        self.size = CGSize.init(width: size.width, height: size.height);
        self.frames = frames;
		
		super.init()
    }
	
	
	deinit {
		print("I'm dead");
	}
	
    
	func prepareForRender(_ completion: @escaping (Result<VideoConvertibleRenderTask>) -> Void)
    {
//		DispatchQueue.main.async
//		{
			let frame = CGRect(origin: CGPoint.zero, size: self.size);
			
			let path = Bundle.main.path(forResource: "blank", ofType: "m4v")!;
			let blankURL = URL.init(fileURLWithPath: path);
			
			let asset = AVURLAsset(url: blankURL);
			
			let videoTrack = asset.tracks(withMediaType: .video).first!;
			
			let composition = AVMutableComposition();
			
			guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
				completion(.failure(error: VideoConvertibleError.error));
				return;
			}
//
			let duration = CMTimeMakeWithSeconds(Float64(self.animationContainer.animationDuration), asset.duration.timescale);
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
		
			let layer = animationContainer.layer;
		
			CATransaction.begin()
			CATransaction.setDisableActions(true);
		
			animationContainer.play();
		
			CATransaction.commit()
		
			parentLayer.addSublayer(layer);
		
		
			let videoComposition = AVMutableVideoComposition();
			
			let frameRate = self.animationContainer.sceneModel?.framerate?.int32Value;
			
			let width = round(self.size.width / 16.0) * 16.0;
			let height = round(self.size.height * (self.size.width / width))
			
			videoComposition.renderSize = CGSize(width: width, height: height);
			videoComposition.instructions = [mainInstruction];
			videoComposition.frameDuration = CMTimeMake(1, frameRate! * 2);
			videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer);
		
			let task = VideoConvertibleRenderTask(main: composition, video: videoComposition, range: range);
			
			completion(.success(value: task));
    }
	
	
	private func createAnimationContainer() -> LOTAnimationView
	{
		let frame = CGRect(origin: CGPoint.zero, size: size);
		
		let animationContainerView = LOTAnimationView(filePath: animation.path);
		animationContainerView.frame = frame;
		animationContainerView.contentMode = .scaleAspectFill;
		animationContainerView.loopAnimation = false;
		
		for (index, image) in frames.enumerated()
		{
			let layerName = "frame_\(index)";
			
			let convertedFrame = animationContainerView.convert(frame, toLayerNamed: layerName);
			
			let imageView = UIImageView(image: image);
			imageView.frame = convertedFrame;
			imageView.contentMode = .scaleAspectFill;
			
			animationContainerView.addSubview(imageView, toLayerNamed: layerName, applyTransform: true);
		}
		
		return animationContainerView;
	}
}
