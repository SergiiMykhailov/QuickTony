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


public final class LottieTransition: NSObject, VideoConvertible, CALayerDelegate
{
    private let animation: URL;
    private let size: CGSize;
    private let frames: [URL];
	private let queue = DispatchQueue(label: "com.visheo.lottie.render", qos: .default);
	private let imageRenderer: UIGraphicsImageRenderer;
	
	private var assetWriter: AVAssetWriter?;
	private var assetWriterInput: AVAssetWriterInput?;
	private var pixelBufferAdapter: AVAssetWriterInputPixelBufferAdaptor?;
	private var animationContainer: LOTAnimationView?;
	
	
    public init(animation: URL, size: CGSize, frames: [URL])
    {
        self.animation = animation;
        self.size = CGSize(width: size.width, height: size.height);
        self.frames = frames;
		self.imageRenderer = UIGraphicsImageRenderer(size: size);
		
		super.init()
    }
	
	
	deinit {
		print("I'm dead");
	}
	
    
	func render(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
    {
		let frame = CGRect(origin: CGPoint.zero, size: self.size);
		let container = createAnimationContainer();
		
		self.animationContainer = container;
		
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
		let duration = CMTimeMakeWithSeconds(Float64(container.animationDuration), asset.duration.timescale);
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
		parentLayer.addSublayer(container.layer);
		
//		container.play();
		
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
		
		container.pop_add(animation, forKey: "ke");
		
		let videoComposition = AVMutableVideoComposition();
		
//		let width = round(self.size.width / 16.0) * 16.0;
//		let height = round(self.size.height * (self.size.width / width))
		
		videoComposition.renderSize = size;//CGSize(width: width, height: height);
		videoComposition.instructions = [mainInstruction];
		videoComposition.frameDuration = CMTimeMake(1, container.sceneModel?.framerate?.int32Value ?? 30);
		videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(postProcessingAsVideoLayer: videoLayer, in: parentLayer);
//		videoComposition.customVideoCompositorClass = LottieComposition.self;
		
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
	
	
	private func createAnimationContainer() -> LOTAnimationView
	{
		let frame = CGRect(origin: CGPoint.zero, size: size);

		let assets = [ "image_1" : frames[0].path, "image_0" : frames[1].path ]
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
		let begin = CACurrentMediaTime();
		
		let image = renderer.image { (ctx) in
			layer.render(in: ctx.cgContext);
		}
		
		let end = CACurrentMediaTime();
		
		let diff = end - begin;
		
		return image.pixelBuffer;
	}
	
	
	func perFrameRender(to url: URL, on queue: DispatchQueue? = nil, completion: @escaping (Result<Void>) -> Void)
	{
		let container = createAnimationContainer();
		self.animationContainer = container;
		
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
			
			self.assetWriter = writer;
			self.assetWriterInput = input;
			self.pixelBufferAdapter = adapter;
			
			guard writer.startWriting() else {
				let error = writer.error ?? VideoConvertibleError.error;
				throw error;
			}
			
			writer.startSession(atSourceTime: time);
			
			input.requestMediaDataWhenReady(on: self.queue, using: { [weak self] in
				
				guard let `self` = self else {
					input.markAsFinished();
					writer.cancelWriting();
					completion(.failure(error: VideoConvertibleError.error));
					return;
				}
				
				while input.isReadyForMoreMediaData
				{
					autoreleasepool {
					
						let progress = CMTimeGetSeconds(time) / animationDuration;
					
						if progress >= 1.0 {
							input.markAsFinished();
							writer.finishWriting {
								switch writer.error
								{
									case .none:
										completion(.success(value: Void()));
									case .some(let error):
										completion(.failure(error: error));
								}
							}
							return;
						}
					
						container.animationProgress = CGFloat(progress);
					
						guard let buffer = self.renderLayer(layerToRender, with: self.imageRenderer) else {
							return;
						}
					
						adapter.append(buffer, withPresentationTime: time);
						time = CMTimeAdd(time, frameDuration);
					}
				}
			})
		}
		catch (let error)
		{
			assetWriterInput?.markAsFinished();
			assetWriter?.cancelWriting();
			
			print("Transition render finished with error \(error)");
			completion(.failure(error: error));
		}
	}
}
