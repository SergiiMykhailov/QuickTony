//
//  LottieTransition.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 10/31/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Lottie
import AVFoundation


public final class LottieTransition: NSObject, VideoConvertible, CALayerDelegate
{
    private let animation: URL;
    private let size: CGSize;
    private let frames: [URL];
	private let queue = DispatchQueue(label: "com.visheo.lottie.render", qos: .default);
	
	
    public init(animation: URL, size: CGSize, frames: [URL])
    {
        self.animation = animation;
        self.size = CGSize(width: size.width, height: size.height);
        self.frames = frames;
		
		super.init()
    }
	
	
	deinit {
		print("I'm dead");
	}
	
    
	func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
    {
		perFrameRender(to: url, on: queue, completion: completion);
    }
	
	
	private func createAnimationContainer() -> LOTAnimationView
	{
		let frame = CGRect(origin: CGPoint.zero, size: size);

		let assets = [ "image_0" : frames[0].path, "image_1" : frames[1].path ]
		let composition = LOTComposition(filePath: animation.path, assetPaths: assets);
		
		let animationContainerView = LOTAnimationView(model: composition, in: nil);
		animationContainerView.frame = frame;
		animationContainerView.contentMode = .scaleAspectFill;
		animationContainerView.loopAnimation = false;

		return animationContainerView;
	}
	
	
//	func oldRender()
//	{
//		let frame = CGRect(origin: CGPoint.zero, size: self.size);
//
//		let path = Bundle.main.path(forResource: "blank", ofType: "m4v")!;
//		let blankURL = URL.init(fileURLWithPath: path);
//
//		let asset = AVURLAsset(url: blankURL);
//
//		let videoTrack = asset.tracks(withMediaType: .video).first!;
//
//		let composition = AVMutableComposition();
//
//		guard let track = composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid) else {
//			completion(.failure(error: VideoConvertibleError.error));
//			return;
//		}
//		//
//		let duration = CMTimeMakeWithSeconds(Float64(self.animationContainer.animationDuration), asset.duration.timescale);
//		let range = CMTimeRangeMake(kCMTimeZero, duration);
//
//		try? track.insertTimeRange(CMTimeRangeMake(kCMTimeZero, duration), of: videoTrack, at: kCMTimeZero);
//
//		let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track);
//
//		let mainInstruction = AVMutableVideoCompositionInstruction();
//		mainInstruction.layerInstructions = [trackInstruction];
//		mainInstruction.timeRange = range;
//
//		let parentLayer = CALayer();
//		let videoLayer = CALayer();
//
//		parentLayer.frame = frame;
//		videoLayer.frame = frame;
//
//		parentLayer.addSublayer(videoLayer);
//
//		let videoComposition = AVMutableVideoComposition();
//
//		let width = round(self.size.width / 16.0) * 16.0;
//		let height = round(self.size.height * (self.size.width / width))
//
//		videoComposition.renderSize = CGSize(width: width, height: height);
//		videoComposition.instructions = [mainInstruction];
//		videoComposition.frameDuration = CMTimeMake(1, 30);
//		videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer);
//
//		let task = VideoConvertibleRenderTask(main: composition, video: videoComposition, range: range);
//
//		completion(.success(value: task));
//	}
	
	
	func renderLayer(_ layer: CALayer, with renderer: UIGraphicsImageRenderer) -> CVPixelBuffer?
	{
		let image = renderer.image { (ctx) in
			layer.draw(in: ctx.cgContext);
		}
		
		return image.pixelBuffer;
	}
	
	
	func perFrameRender(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
	{
		let container = createAnimationContainer();
		
		let startFrame = container.sceneModel?.startFrame?.intValue ?? 0;
		let endFrame = container.sceneModel?.endFrame?.intValue ?? 0;
		let frameRate = container.sceneModel?.framerate?.intValue ?? 0;
		
		let animationDuration = Double(endFrame - startFrame) / Double(frameRate)
		let frameDuration = CMTimeMake(1, Int32(frameRate));
		
		var time = kCMTimeZero;
		
		let settings: [String: Any] = [ AVVideoCodecKey : AVVideoCodecH264,
		                                AVVideoWidthKey : NSNumber(value: Float(size.width)),
		                                AVVideoHeightKey : NSNumber(value: Float(size.height))
		]
		
		let pixelBufferAdapterAttributes: [String : Any] = [ String(kCVPixelBufferPixelFormatTypeKey) : kCVPixelFormatType_32ARGB ];
		
		if FileManager.default.fileExists(atPath: url.path) {
			try? FileManager.default.removeItem(at: url);
		}
		
		let layerToRender = container.layer;
		let renderer = UIGraphicsImageRenderer(size: size);
		
		do
		{
			let writer = try AVAssetWriter(outputURL: url, fileType: .mp4);
			let input = AVAssetWriterInput(mediaType: .video, outputSettings: settings);
			input.expectsMediaDataInRealTime = false;
			
			guard writer.canAdd(input) else {
				throw VideoConvertibleError.error;
			}
			
			writer.add(input);
			
			let adapter = AVAssetWriterInputPixelBufferAdaptor(assetWriterInput: input, sourcePixelBufferAttributes: pixelBufferAdapterAttributes);
			
			guard writer.startWriting() else {
				throw VideoConvertibleError.error;
			}
			
			writer.startSession(atSourceTime: time);
			
			input.requestMediaDataWhenReady(on: self.queue, using: { [weak self] in
				
				guard let `self` = self else { return; }
				
				while input.isReadyForMoreMediaData
				{
					let progress = CMTimeGetSeconds(time) / animationDuration;
					
					if progress >= 1.0 {
						input.markAsFinished();
						writer.finishWriting {
							print("finished")
						}
						break;
					}
					
					container.animationProgress = CGFloat(progress);
					
					guard let buffer = self.renderLayer(layerToRender, with: renderer) else {
						break;
					}
					
					adapter.append(buffer, withPresentationTime: time);
					time = CMTimeAdd(time, frameDuration);
				}
			})
		}
		catch (let error)
		{
			completion(.failure(error: error));
		}
	}
}
