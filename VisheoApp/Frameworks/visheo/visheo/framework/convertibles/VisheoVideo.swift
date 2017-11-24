//
//  VisheoVideo.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/20/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation

class VisheoVideo: VideoConvertible
{
	private let timeline: URL;
	private let video: URL;
	private let audio: URL;
	private let renderSize: CGSize;
	
	
	init(timeline: URL, video: URL, audio: URL, size: CGSize)
	{
		self.timeline = timeline;
		self.video = video;
		self.audio = audio;
		self.renderSize = size;
	}
	
	
	var renderQueueSupport: ProcessingQueueType {
		return .concurrent;
	}
	
	
	func render(to url: URL, on queue: DispatchQueue?, completion: @escaping (Result<Void>) -> Void)
	{
		do
		{
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
				audioInputParams.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.1, timeRange: start);
				
				let end = CMTimeRangeMake(CMTimeAdd(time, videoAsset.duration), duration)
				audioInputParams.setVolumeRamp(fromStartVolume: 0.1, toEndVolume: 1.0, timeRange: end);
			}
			
//			for (index, motion) in motions.enumerated()
//			{
//				guard let motionURL = motion.output else {
//					throw VideoConvertibleError.error;
//				}
//
//				let motionAsset = AVURLAsset(url: motionURL);
//
//				guard let motionTrack = motionAsset.tracks(withMediaType: .video).first else {
//					throw VideoConvertibleError.error;
//				}
//
//				try videoTrack.insertTimeRange(motionTrack.timeRange, of: motionTrack, at: time);
//
//				trackInstruction.setTransform(CGAffineTransform.identity, at: time);
//
//				if (!motionTrack.naturalSize.equalTo(renderSize))
//				{
//					let scale = renderSize.width / motionTrack.naturalSize.width;
//					let transform = CGAffineTransform(scaleX: scale, y: scale);
//					trackInstruction.setTransform(transform, at: time);
//				}
//
//				if let audioTrack = motionAsset.tracks(withMediaType: .audio).first, motion.hasAudio {
//					try videoSoundTrack.insertTimeRange(audioTrack.timeRange, of: audioTrack, at: time);
//
//					let duration = CMTimeMakeWithSeconds(1.0, motionAsset.duration.timescale);
//
//					let start = CMTimeRangeMake(CMTimeSubtract(time, duration), duration);
//					audioInputParams.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.1, timeRange: start);
//
//					let end = CMTimeRangeMake(CMTimeAdd(time, motionAsset.duration), duration)
//					audioInputParams.setVolumeRamp(fromStartVolume: 0.1, toEndVolume: 1.0, timeRange: end);
//				}
//
//				if index >= transitions.count {
//					time = CMTimeAdd(time, motionTrack.timeRange.end);
//					continue;
//				}
//
//				let transition = transitions[index];
//
//				guard let transitionURL = transition.output else {
//					throw VideoConvertibleError.error;
//				}
//
//				let transitionAsset = AVURLAsset(url: transitionURL);
//
//				guard let transitionTrack = transitionAsset.tracks(withMediaType: .video).first else {
//					throw VideoConvertibleError.error;
//				}
//
//				time = CMTimeAdd(time, transition.fromMotionFrameTime!);
//
//				try videoTrack.insertTimeRange(transitionTrack.timeRange, of: transitionTrack, at: time);
//
//				if (!transitionTrack.naturalSize.equalTo(renderSize))
//				{
//					let scale = renderSize.width / transitionTrack.naturalSize.width;
//					let transform = CGAffineTransform(scaleX: scale, y: scale);
//					trackInstruction.setTransform(transform, at: time);
//				}
//
//				var tm = kCMTimeInvalid;
//
//				try autoreleasepool {
//					let generator = AVAssetImageGenerator(asset: transitionAsset);
//					try generator.copyCGImage(at: transitionTrack.timeRange.end, actualTime: &tm);
//				}
//
//				time = CMTimeAdd(time, tm);
//			}
			
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

			guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPreset640x480) else {
				throw VideoConvertibleError.error;
			}
			
			session.outputURL = url;
			session.outputFileType = .mp4;
			session.videoComposition = videoComposition;
			session.audioMix = audioMix;
			
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
