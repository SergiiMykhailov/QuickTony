//
//  VisheoVideo.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/20/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation

public typealias VisheoVideoComposition =  (mainComposition: AVComposition, videoComposition: AVVideoComposition, audioMix: AVAudioMix);


public final class VisheoVideo: VideoConvertible
{
	private let timeline: URL;
	private let video: URL;
	private let audio: URL;
	private let quality: RenderQuality;
	
	
	public init(timeline: URL, video: URL, audio: URL, quality: RenderQuality)
	{
		self.timeline = timeline;
		self.video = video;
		self.audio = audio;
		self.quality = quality;
	}
	
	
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	
	public func prepareComposition() throws -> VisheoVideoComposition
	{
		let renderSize = quality.renderSize;
		
		let composition = AVMutableComposition();
		
		let audio = AVURLAsset(url: self.audio);
		
		let videoTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		
		let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack);
		
		let videoID = composition.unusedTrackID();
		let videoSoundTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: videoID))!;
		
		let audioID = composition.unusedTrackID();
		let musicTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioID))!;
		
		var time = kCMTimeZero;
		
		let videoInputParams = AVMutableAudioMixInputParameters();
		videoInputParams.trackID = videoID;
		videoInputParams.setVolume(1.0, at: kCMTimeZero);
		
		let audioInputParams = AVMutableAudioMixInputParameters();
		audioInputParams.trackID = audioID;
		audioInputParams.setVolume(1.0, at: kCMTimeZero);
		
		
		let timelineAsset = AVURLAsset(url: timeline);
		
		guard let timelineTrack = timelineAsset.tracks(withMediaType: .video).first else {
			throw VideoConvertibleError.error;
		}
		
		try videoTrack.insertTimeRange(timelineTrack.timeRange, of: timelineTrack, at: time);
		
		trackInstruction.setTransform(CGAffineTransform.identity, at: time);
		
		if (!timelineTrack.naturalSize.equalTo(renderSize))
		{
			let scale = renderSize.width / timelineTrack.naturalSize.width;
			let transform = CGAffineTransform(scaleX: scale, y: scale);
			trackInstruction.setTransform(transform, at: time);
		}
		
		let videoAsset = AVURLAsset(url: video);
		
		guard let videoAssetTrack = videoAsset.tracks(withMediaType: .video).first else {
			throw VideoConvertibleError.error;
		}
		
		time = CMTimeSubtract(timelineTrack.timeRange.end, CMTime(value: 1, timescale: CMTimeScale(videoAssetTrack.nominalFrameRate)));
		
		try videoTrack.insertTimeRange(videoAssetTrack.timeRange, of: videoAssetTrack, at: time);
		
		trackInstruction.setTransform(CGAffineTransform.identity, at: time);
		
		if (!videoAssetTrack.naturalSize.equalTo(renderSize))
		{
			let scale = renderSize.width / videoAssetTrack.naturalSize.width;
			let transform = CGAffineTransform(scaleX: scale, y: scale);
			trackInstruction.setTransform(transform, at: time);
		}
		
		if let soundtrack = videoAsset.tracks(withMediaType: .audio).first
		{
			try videoSoundTrack.insertTimeRange(soundtrack.timeRange, of: soundtrack, at: time);
			
			let duration = CMTimeMakeWithSeconds(1.0, timelineAsset.duration.timescale);
			
			let start = CMTimeRangeMake(CMTimeSubtract(time, duration), duration);
			audioInputParams.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.05, timeRange: start);
			
			let end = CMTimeRangeMake(CMTimeAdd(time, videoAsset.duration), duration)
			audioInputParams.setVolumeRamp(fromStartVolume: 0.05, toEndVolume: 1.0, timeRange: end);
		}
		
		guard let audioTrack = audio.tracks(withMediaType: .audio).first else {
			throw VideoConvertibleError.error;
		}
		
		try musicTrack.insertTimeRange(videoTrack.timeRange, of: audioTrack, at: kCMTimeZero);
		
		let mainInstruction = AVMutableVideoCompositionInstruction();
		mainInstruction.layerInstructions = [ trackInstruction ];
		mainInstruction.timeRange = videoTrack.timeRange;
		
		let videoComposition = AVMutableVideoComposition();
		
		videoComposition.renderSize = renderSize;
		videoComposition.instructions = [mainInstruction];
		videoComposition.frameDuration = videoTrack.minFrameDuration;
		
		let audioMix = AVMutableAudioMix();
		audioMix.inputParameters = [ videoInputParams, audioInputParams ];
		
		return (composition, videoComposition, audioMix);
	}
	
	
	func render(to url: URL, on queue: DispatchQueue?, completion: @escaping (Result<Void>) -> Void)
	{
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
}
