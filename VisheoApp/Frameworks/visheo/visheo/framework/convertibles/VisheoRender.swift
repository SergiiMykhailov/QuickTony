//
//  VisheoRender.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/20/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation

public typealias VisheoVideoComposition =  (mainComposition: AVComposition, videoComposition: AVVideoComposition, audioMix: AVAudioMix);


public final class VisheoRender: VideoConvertible
{
	private let timeline: URL;
	private let video: URL;
	private let audio: URL?;
	private let outro: URL?
	private let quality: RenderQuality;
	
	public init(timeline: URL, video: URL, audio: URL? = nil, outro: URL? = nil, quality: RenderQuality) {
		self.timeline = timeline;
		self.video = video;
		self.audio = audio;
		self.outro = outro;
		self.quality = quality;
	}
	
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	func render(to url: URL, on queue: DispatchQueue?, completion: @escaping (Result<Void>) -> Void) {
		do
		{
			let results = try prepareComposition();
			
			guard let session = AVAssetExportSession(asset: results.mainComposition, presetName: quality.exportSessionPreset) else {
				throw VideoConvertibleError.error;
			}
			
			session.outputURL = url;
			session.outputFileType = .mp4;
			session.videoComposition = results.videoComposition;
			session.audioMix = results.audioMix;
			
			session.exportAsynchronously {
				if let e = session.error {
					completion(.failure(error: e));
				} else {
					completion(.success(value: Void()))
				}
			}
		}
		catch (let error) {
			completion(.failure(error: error));
		}
	}
	
	
	public func prepareComposition() throws -> VisheoVideoComposition
	{
		let renderSize = quality.renderSize;
		
		let composition = AVMutableComposition();
		
		let videoTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		
		let videoID = composition.unusedTrackID();
		let videoSoundTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: videoID))!;
		
		var time = kCMTimeZero;
		
		let videoInputParams = AVMutableAudioMixInputParameters();
		videoInputParams.trackID = videoID;
		videoInputParams.setVolume(1.0, at: kCMTimeZero);
		
		var audioInputParams: AVMutableAudioMixInputParameters? = nil;
		var audio: AVURLAsset? = nil;
		var musicTrack: AVMutableCompositionTrack? = nil;
		
		if let audioURL = self.audio {
			audio = AVURLAsset(url: audioURL);
			
			let audioID = composition.unusedTrackID();
			musicTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioID);
			
			audioInputParams = AVMutableAudioMixInputParameters();
			audioInputParams?.trackID = audioID;
			audioInputParams?.setVolume(1.0, at: kCMTimeZero);
		}
		
		var instructions: [ AVMutableVideoCompositionInstruction ] = []
		
		
		let timelineAsset = AVURLAsset(url: timeline);
		
		let timelineInfo = try appendPassthroughVideo(from: timelineAsset, to: videoTrack, size: renderSize, at: kCMTimeZero);
		instructions.append(contentsOf: timelineInfo.instructions);
	
		
		let timelineEnd = timelineAsset.duration;
		let frameDuration = CMTime(value: 1, timescale: CMTimeScale(timelineInfo.track.nominalFrameRate));
		let videoStartTime = CMTimeSubtract(timelineEnd, frameDuration);
		
		let videoAsset = AVURLAsset(url: video);
		let videoCompositionInstruction = try appendPassthroughVideo(from: videoAsset, to: videoTrack, size: renderSize, at: videoStartTime);
		
//		guard let timelineTrack = timelineAsset.tracks(withMediaType: .video).first else {
//			throw VideoConvertibleError.error;
//		}
//
//		try videoTrack.insertTimeRange(timelineTrack.timeRange, of: timelineTrack, at: time);
//
//		if (!timelineTrack.naturalSize.equalTo(renderSize)) {
//			let timelineInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: timelineTrack);
////			instructions.append(timelineInstruction);
//
//			let scale = renderSize.width / timelineTrack.naturalSize.width;
//			let transform = CGAffineTransform(scaleX: scale, y: scale);
//			timelineInstruction.setTransform(transform, at: kCMTimeZero);
//		}
		
		
		// video asset
//		let videoAsset = AVURLAsset(url: video);
//
//		guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
//			throw VideoConvertibleError.error;
//		}
//
//		time = CMTimeSubtract(timelineTrack.timeRange.end, CMTime(value: 1, timescale: CMTimeScale(videoAssetTrack.nominalFrameRate)));
//
//		try videoTrack.insertTimeRange(videoAssetTrack.timeRange, of: videoAssetTrack, at: time);
//
//		let videoTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoAssetTrack)
////		instructions.append(videoTrackInstruction);
//
//		if (!videoAssetTrack.naturalSize.equalTo(renderSize)) {
//			let scale = renderSize.width / videoAssetTrack.naturalSize.width;
//			let transform = CGAffineTransform(scaleX: scale, y: scale);
//			videoTrackInstruction.setTransform(transform, at: kCMTimeZero);
//		}
//
//		if let videoSound = videoAsset.tracks(withMediaType: .audio).first {
//			try videoSoundTrack.insertTimeRange(videoSound.timeRange, of: videoSound, at: time);
//
//			let duration = CMTimeMakeWithSeconds(1.0, timelineAsset.duration.timescale);
//
//			let start = CMTimeRangeMake(CMTimeSubtract(time, duration), duration);
//			audioInputParams?.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.05, timeRange: start);
//		}
//
//
//		// outro
//		if let outroURL = outro
//		{
//			let outroAsset = AVURLAsset(url: outroURL);
//
//			guard let outroVideoTrack = outroAsset.tracks(withMediaType: .video).first else {
//				throw VideoConvertibleError.error;
//			}
//
//			let crossfadeDuration = CMTimeMakeWithSeconds(2.0, videoAsset.duration.timescale);
//			let crossfadeStart = CMTimeSubtract(videoTrack.timeRange.end, crossfadeDuration);
//			let crossfadeRange = CMTimeRangeMake(crossfadeStart, crossfadeDuration);
//
//			let outroRange = CMTimeRangeMake(crossfadeStart, outroAsset.duration);
//
//			try videoTrack.insertTimeRange(outroVideoTrack.timeRange, of: outroVideoTrack, at: crossfadeStart);
//
//			videoTrackInstruction.setOpacityRamp(fromStartOpacity: 1.0, toEndOpacity: 0.0, timeRange: crossfadeRange);
//
//			let outroTrackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: outroVideoTrack);
////			instructions.append(outroTrackInstruction);
//
//			if (!outroVideoTrack.naturalSize.equalTo(renderSize)) {
//				let scale = renderSize.width / outroVideoTrack.naturalSize.width;
//				let transform = CGAffineTransform(scaleX: scale, y: scale);
//				outroTrackInstruction.setTransform(transform, at: kCMTimeZero);
//			}
//
//			let duration = CMTimeMakeWithSeconds(2.0, videoTrack.naturalTimeScale);
//			let rampStart = CMTimeSubtract(crossfadeStart, duration);
//			let rampRange = CMTimeRangeMake(rampStart, duration);
//
//			audioInputParams?.setVolumeRamp(fromStartVolume: 0.05, toEndVolume: 0.2, timeRange: rampRange);
//			audioInputParams?.setVolumeRamp(fromStartVolume: 0.2, toEndVolume: 0.0, timeRange: outroRange);
//		}
//
//		if let _ = audio, let _ = musicTrack {
//			guard let audioTrack = audio?.tracks(withMediaType: .audio).first else {
//				throw VideoConvertibleError.error;
//			}
//			try musicTrack?.insertTimeRange(videoTrack.timeRange, of: audioTrack, at: kCMTimeZero);
//		}
//
////		let mainInstruction = AVMutableVideoCompositionInstruction();
////		mainInstruction.layerInstructions = instructions;
////		mainInstruction.timeRange = videoTrack.timeRange;
		
		let videoComposition = AVMutableVideoComposition();
		
		videoComposition.renderSize = renderSize;
		videoComposition.instructions = instructions;
		videoComposition.frameDuration = videoTrack.minFrameDuration;
		
		var audioMixInputParams = [ videoInputParams ]
		if let audioParams = audioInputParams {
			audioMixInputParams.append(audioParams);
		}
		
		let audioMix = AVMutableAudioMix();
		audioMix.inputParameters = audioMixInputParams;
		
		return (composition, videoComposition, audioMix);
	}
	
	
	typealias VideoInfo = (track: AVAssetTrack, instructions: [AVMutableVideoCompositionInstruction]);
	
	
	func appendPassthroughVideo(from asset: AVAsset, to compositionTrack: AVMutableCompositionTrack, size: CGSize, at time: CMTime) throws -> VideoInfo {
		guard let videoTrack = asset.tracks(withMediaType: .video).first else {
			throw VideoConvertibleError.error;
		}
		
		try compositionTrack.insertTimeRange(videoTrack.timeRange, of: videoTrack, at: time);
		
		let instruction = AVMutableVideoCompositionInstruction();
		instruction.timeRange = CMTimeRangeMake(kCMTimeZero, asset.duration);
		
		let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack);
		layerInstruction.setTransform(.identity, at: kCMTimeZero);
		
		if (!videoTrack.naturalSize.equalTo(size)) {
			let scale = size.width / videoTrack.naturalSize.width;
			let transform = CGAffineTransform(scaleX: scale, y: scale);
			layerInstruction.setTransform(transform, at: kCMTimeZero);
		}
		
		instruction.layerInstructions = [ layerInstruction ];
		return (videoTrack, [ instruction ]);
	}
	
}
