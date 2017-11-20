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
	private let motions: [MotionTask];
	private let transitions: [TransitionTask];
	private let audio: URL;
	private let renderSize: CGSize;
	
	
	init(motions: [MotionTask], transitions: [TransitionTask], audio: URL, size: CGSize)
	{
		self.motions = motions;
		self.transitions = transitions;
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
			
			let videoTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
			
			let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack);
			
			let audio = AVURLAsset(url: self.audio);
			let videoSoundTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))!;
			let musicTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))!;
			
			var time = kCMTimeZero;
			
			for (index, motion) in motions.enumerated()
			{
				guard let motionURL = motion.output else {
					throw VideoConvertibleError.error;
				}
				
				let motionAsset = AVURLAsset(url: motionURL);
				
				guard let motionTrack = motionAsset.tracks(withMediaType: .video).first else {
					throw VideoConvertibleError.error;
				}
				
				try videoTrack.insertTimeRange(motionTrack.timeRange, of: motionTrack, at: time);
				
				trackInstruction.setTransform(CGAffineTransform.identity, at: time);
				
				if (!motionTrack.naturalSize.equalTo(renderSize))
				{
					let scale = renderSize.width / motionTrack.naturalSize.width;
					let transform = CGAffineTransform(scaleX: scale, y: scale);
					trackInstruction.setTransform(transform, at: time);
				}
				
				if index >= transitions.count {
					time = CMTimeAdd(time, motionTrack.timeRange.end);
					continue;
				}
				
				let transition = transitions[index];
				
				guard let transitionURL = transition.output else {
					throw VideoConvertibleError.error;
				}
				
				let transitionAsset = AVURLAsset(url: transitionURL);
				
				guard let transitionTrack = transitionAsset.tracks(withMediaType: .video).first else {
					throw VideoConvertibleError.error;
				}
				
				time = CMTimeAdd(time, transition.fromMotionFrameTime!);
				
				try videoTrack.insertTimeRange(transitionTrack.timeRange, of: transitionTrack, at: time);
				
				if (!transitionTrack.naturalSize.equalTo(renderSize))
				{
					let scale = renderSize.width / transitionTrack.naturalSize.width;
					let transform = CGAffineTransform(scaleX: scale, y: scale);
					trackInstruction.setTransform(transform, at: time);
				}
				
				var tm = kCMTimeInvalid;
				
				try autoreleasepool {
					let generator = AVAssetImageGenerator(asset: transitionAsset);
					try generator.copyCGImage(at: transitionTrack.timeRange.end, actualTime: &tm);
				}

				time = CMTimeAdd(time, tm);
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

			guard let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
				throw VideoConvertibleError.error;
			}
			
			session.outputURL = url;
			session.outputFileType = .mp4;
			session.videoComposition = videoComposition;
			
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
