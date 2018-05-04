//
//  VisheoRender.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/20/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation
import CoreAudio

public typealias VisheoVideoComposition = (mainComposition: AVComposition, videoComposition: AVVideoComposition, audioMix: AVAudioMix);


public enum RenderError: Error {
	case missingVideoTrack(url: URL);
	case missingAudioTrack(url: URL);
	
	case invalidComposition
	case invalidReaderOutputs
	case invalidWriterInputs
	case assetWriterFailed
	case missingVideoTrackDescription
}


enum VideoEffects {
	case resize(with: ResizeEffect)
	case opacityRamp(from: OpacityRamp, to: OpacityRamp)
}


struct OpacityRamp {
	let track: AVAssetTrack;
	let from: Double;
	let to: Double;
}

struct ResizeEffect {
	let size: CGSize;
	let track: AVAssetTrack;
}


public final class VisheoRender: VideoConvertible
{
	private let timeline: URL;
	private let video: URL;
	private let audio: URL?;
	private let outro: URL?
	private let quality: RenderQuality;
	
	private let exportVideoBitrate = 3_000_000;
	private let exportAudioBitrate = 128_000;
	
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
			
			let audioTracks = results.mainComposition.tracks(withMediaType: .audio);
			let videoTracks = results.mainComposition.tracks(withMediaType: .video);
			
			guard !videoTracks.isEmpty, !audioTracks.isEmpty else {
				throw RenderError.invalidComposition;
			}
			
			let decompressionAudioSettings = [ AVFormatIDKey : kAudioFormatLinearPCM ]
			let audioMixOutput = AVAssetReaderAudioMixOutput(audioTracks: audioTracks, audioSettings: decompressionAudioSettings);
			audioMixOutput.audioMix = results.audioMix;
			
			let decompressionVideoSettings: [String: Any] = [ kCVPixelBufferPixelFormatTypeKey as String : kCVPixelFormatType_422YpCbCr8,
															  kCVPixelBufferIOSurfacePropertiesKey as String : [:]];
			let videoCompositionOutput = AVAssetReaderVideoCompositionOutput(videoTracks: videoTracks, videoSettings: decompressionVideoSettings);
			videoCompositionOutput.videoComposition = results.videoComposition;
			
			let reader = try AVAssetReader(asset: results.mainComposition);
			
			guard reader.canAdd(audioMixOutput), reader.canAdd(videoCompositionOutput) else {
				throw RenderError.invalidReaderOutputs;
			}
			
			reader.add(audioMixOutput);
			reader.add(videoCompositionOutput);
			
			let writer = try AVAssetWriter(outputURL: url, fileType: .mp4);
			
			let compressionVideoSettings: [String : Any] = [ AVVideoCompressionPropertiesKey : [ AVVideoAverageBitRateKey : exportVideoBitrate ],
															 AVVideoCodecKey : AVVideoCodecH264,
															 AVVideoHeightKey: quality.renderSize.height,
															 AVVideoWidthKey: quality.renderSize.width
															]
			
			guard let videoFormatDescription = videoTracks[0].formatDescriptions.last else {
				throw RenderError.missingVideoTrackDescription;
			}
			
			let videoInput = AVAssetWriterInput(mediaType: .video, outputSettings: compressionVideoSettings, sourceFormatHint: (videoFormatDescription as! CMFormatDescription));
			videoInput.expectsMediaDataInRealTime = false;
			
			var stereoChannelLayout = AudioChannelLayout();
			stereoChannelLayout.mChannelLayoutTag = kAudioChannelLayoutTag_Stereo;
			stereoChannelLayout.mChannelBitmap = AudioChannelBitmap(rawValue: 0);
			stereoChannelLayout.mNumberChannelDescriptions = 0;
			
			let channelLayoutData = Data(bytes: &stereoChannelLayout, count: MemoryLayout<AudioChannelLayout>.size);
			
			let compressionAudioSettings: [String: Any] = [ AVFormatIDKey : kAudioFormatMPEG4AAC,
															AVEncoderBitRateKey : exportAudioBitrate,
															AVSampleRateKey : 44100,
															AVChannelLayoutKey : channelLayoutData,
															AVNumberOfChannelsKey : 2
														]
			
			let audioInput = AVAssetWriterInput(mediaType: .audio, outputSettings: compressionAudioSettings);
			audioInput.expectsMediaDataInRealTime = false;
			
			guard writer.canAdd(videoInput), writer.canAdd(audioInput) else {
				throw RenderError.invalidWriterInputs;
			}
			
			writer.add(videoInput);
			writer.add(audioInput);
			
			writer.startWriting();
			reader.startReading();
			
			writer.startSession(atSourceTime: kCMTimeZero);
			
			let group = DispatchGroup();
			let processingQueue = DispatchQueue(label: "com.visheo.assetWriter");
			
			group.enter();
			videoInput.requestMediaDataWhenReady(on: processingQueue) {
				while videoInput.isReadyForMoreMediaData {
					if let sample = videoCompositionOutput.copyNextSampleBuffer() {
						videoInput.append(sample);
					} else {
						videoInput.markAsFinished();
						group.leave();
						break;
					}
				}
			}
			
			group.enter()
			audioInput.requestMediaDataWhenReady(on: processingQueue) {
				while audioInput.isReadyForMoreMediaData {
					if let sample = audioMixOutput.copyNextSampleBuffer() {
						audioInput.append(sample);
					} else {
						audioInput.markAsFinished();
						group.leave();
						break;
					}
				}
			}
			
			group.notify(queue: DispatchQueue.global()) {
				writer.finishWriting {
					switch writer.status {
						case .completed:
							completion(.success(value: Void()));
						case .writing:
							break;
						default:
							let error = writer.error ?? RenderError.assetWriterFailed;
							completion(.failure(error: error));
					}
				}
				reader.cancelReading();
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
		
		let videoID = composition.unusedTrackID();
		let videoCompositionSoundtrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: videoID))!;
		
		let videoInputParams = AVMutableAudioMixInputParameters();
		videoInputParams.trackID = videoID;
		videoInputParams.setVolume(1.0, at: kCMTimeZero);
		
		var audioInputParams: AVMutableAudioMixInputParameters? = nil;
		var musicCompositionTrack: AVMutableCompositionTrack? = nil;
		
		if let _ = audio {
			let audioID = composition.unusedTrackID();
			musicCompositionTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: audioID);
			
			audioInputParams = AVMutableAudioMixInputParameters();
			audioInputParams?.trackID = audioID;
			audioInputParams?.setVolume(1.0, at: kCMTimeZero);
		}
		
		let timelineAsset = AVURLAsset(url: timeline, options: [ AVURLAssetPreferPreciseDurationAndTimingKey : true ]);
		
		guard let timelineVideoTrack = timelineAsset.tracks(withMediaType: .video).first else {
			throw RenderError.missingVideoTrack(url: timeline);
		}
		
		let mainVideoAsset = AVURLAsset(url: video, options: [ AVURLAssetPreferPreciseDurationAndTimingKey : true ]);
		
		guard let mainVideoTrack = mainVideoAsset.tracks(withMediaType: .video).first else {
			throw RenderError.missingVideoTrack(url: video);
		}
		
		let outroCompositionTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;

		var timeRanges: CompositionTimes;
		
		if let outroURL = outro {
			let outroAsset = AVURLAsset(url: outroURL, options: [ AVURLAssetPreferPreciseDurationAndTimingKey : true ]);
			
			guard let track = outroAsset.tracks(withMediaType: .video).first else {
				throw RenderError.missingVideoTrack(url: outroURL);
			}
			
			var crossfadeDuration = 0.7;
			crossfadeDuration = min(crossfadeDuration, CMTimeGetSeconds(mainVideoAsset.duration) / 3);
			
			timeRanges = calculateTimeRanges(timeline: timelineVideoTrack, video: mainVideoTrack, outro: track, crossfadeDuration: crossfadeDuration);
			try outroCompositionTrack.insertTimeRange(track.timeRange, of: track, at: timeRanges.outroStart);
			
			var fadeInDuration = CMTimeMakeWithSeconds(1.5, outroAsset.duration.timescale);
			var fadeInStart = CMTimeSubtract(timeRanges.outroStart, fadeInDuration);
			var outroRamp: Float = 0.3;
			
			if fadeInStart < timeRanges.mainVideoStart {
				fadeInStart = timeRanges.mainVideoStart;
				fadeInDuration = CMTimeSubtract(timeRanges.outroStart, timeRanges.mainVideoStart);
				outroRamp = 0.2;
			}
			
			audioInputParams?.setVolumeRamp(fromStartVolume: 0.1, toEndVolume: outroRamp, timeRange: CMTimeRangeMake(fadeInStart, fadeInDuration));
			audioInputParams?.setVolumeRamp(fromStartVolume: outroRamp, toEndVolume: 0.0, timeRange: CMTimeRangeMake(timeRanges.outroStart, outroAsset.duration));
		} else {
			timeRanges = calculateTimeRanges(timeline: timelineVideoTrack, video: mainVideoTrack, outro: nil, crossfadeDuration: 0.0);
		}
		
		let timelineCompositionTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		try timelineCompositionTrack.insertTimeRange(timelineVideoTrack.timeRange, of: timelineVideoTrack, at: kCMTimeZero);
		
		let mainVideoCompositionTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		try mainVideoCompositionTrack.insertTimeRange(mainVideoTrack.timeRange, of: mainVideoTrack, at: timeRanges.mainVideoStart);
		
		let duration = CMTimeMakeWithSeconds(1.5, timelineAsset.duration.timescale);
		let start = CMTimeRangeMake(CMTimeSubtract(timeRanges.mainVideoStart, duration), duration);
		audioInputParams?.setVolumeRamp(fromStartVolume: 1.0, toEndVolume: 0.04, timeRange: start);
		
		if let videoSound = mainVideoAsset.tracks(withMediaType: .audio).first {
			try videoCompositionSoundtrack.insertTimeRange(videoSound.timeRange, of: videoSound, at: timeRanges.mainVideoStart);
		}
		
		if let audioURL = audio {
			let audioAsset = AVURLAsset(url: audioURL, options: [ AVURLAssetPreferPreciseDurationAndTimingKey : true ]);
			
			guard let audioTrack = audioAsset.tracks(withMediaType: .audio).first else {
				throw RenderError.missingAudioTrack(url: audioURL);
			}
			try musicCompositionTrack?.insertTimeRange(CMTimeRangeMake(kCMTimeZero, timeRanges.totalDuration), of: audioTrack, at: kCMTimeZero);
		}

		
		let timelineResize = VideoEffects.resize(with: ResizeEffect(size: renderSize, track: timelineCompositionTrack));
		let mainVideoResize = VideoEffects.resize(with: ResizeEffect(size: renderSize, track: mainVideoCompositionTrack));
		let outroResize = VideoEffects.resize(with: ResizeEffect(size: renderSize, track: outroCompositionTrack));

		let rampFrom = OpacityRamp(track: mainVideoCompositionTrack, from: 1.0, to: 0.0);
		let rampTo = OpacityRamp(track: outroCompositionTrack, from: 0.0, to: 1.0);
		
		let crossfade = VideoEffects.opacityRamp(from: rampFrom, to: rampTo);
		
		var compositionInstructions: [AVMutableVideoCompositionInstruction] = [];
		
		let i1 = add(effects: [ timelineResize ], in: timeRanges.timelinePassthrough);
		let i2 = add(effects: [ mainVideoResize, timelineResize ], in: timeRanges.overlap);
		let i3 = add(effects: [ mainVideoResize ], in: timeRanges.videoPassthrough);
		let i4 = add(effects: [ crossfade, mainVideoResize, outroResize ], in: timeRanges.crossfade);
		let i5 = add(effects: [ outroResize ], in: timeRanges.outroPassthrough);
		
		compositionInstructions = [ i1, i2, i3, i4, i5 ];
		
		
		let videoComposition = AVMutableVideoComposition();
		
		videoComposition.renderSize = renderSize;
		videoComposition.instructions = compositionInstructions;
		videoComposition.frameDuration = timelineVideoTrack.minFrameDuration;
		
		var audioMixInputParams = [ videoInputParams ]
		if let audioParams = audioInputParams {
			audioMixInputParams.append(audioParams);
		}
		
		let audioMix = AVMutableAudioMix();
		audioMix.inputParameters = audioMixInputParams;
		
		return (composition, videoComposition, audioMix);
	}
	
	
	typealias LayerInstructions = [AVMutableVideoCompositionLayerInstruction];
	
	
	func add(effects: [VideoEffects], in range: CMTimeRange) -> AVMutableVideoCompositionInstruction {
		let compositionInstruction = AVMutableVideoCompositionInstruction();
		compositionInstruction.timeRange = range;
		
		var layerInstructions: LayerInstructions = []
		
		for effect in effects {
			switch effect
			{
				case .resize(let effect):
					layerInstructions = resize(with: effect, in: range, instructions: layerInstructions);
				case .opacityRamp(let from, let to):
					layerInstructions = opacityRamp(from: from, to: to, in: range, instructions: layerInstructions);
				default:
					break;
			}
		}
		
		compositionInstruction.layerInstructions = layerInstructions;
		return compositionInstruction;
	}
	
	
	func resize(with effect: ResizeEffect, in range: CMTimeRange, instructions: LayerInstructions) -> LayerInstructions
	{
		var layerInstruction: AVMutableVideoCompositionLayerInstruction;
		var mutInstructions = instructions;
		
		if let idx = instructions.index(where: { $0.trackID == effect.track.trackID }) {
			layerInstruction = instructions[idx];
		} else {
			layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: effect.track);
			mutInstructions.append(layerInstruction);
		}
	
		var transform = CGAffineTransform.identity;
		if !effect.track.naturalSize.equalTo(effect.size) {
			let scale = effect.size.width / effect.track.naturalSize.width;
			transform = CGAffineTransform(scaleX: scale, y: scale);
		}
		
		layerInstruction.setTransform(transform, at: kCMTimeZero);
		return mutInstructions;
	}
	
	
	func opacityRamp(from: OpacityRamp, to: OpacityRamp, in range: CMTimeRange, instructions: LayerInstructions) -> LayerInstructions {
		var mutInstructions = instructions;
		
		for ramp in [ from, to ] {
			var layerInstruction: AVMutableVideoCompositionLayerInstruction;
			
			if let idx = instructions.index(where: { $0.trackID == ramp.track.trackID }) {
				layerInstruction = instructions[idx];
			} else {
				layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: ramp.track);
				mutInstructions.append(layerInstruction);
			}
			
			layerInstruction.setOpacityRamp(fromStartOpacity: Float(ramp.from), toEndOpacity: Float(ramp.to), timeRange: range);
		}

		return mutInstructions;
	}
	
	struct CompositionTimes {
		var timelinePassthrough = CMTimeRange();
		var overlap = CMTimeRange();
		var videoPassthrough = CMTimeRange();
		var crossfade = CMTimeRange();
		var outroPassthrough = CMTimeRange();
		
		
		var timelineStart: CMTime {
			return kCMTimeZero;
		}
		
		var mainVideoStart: CMTime {
			return timelinePassthrough.end;
		}
		
		var outroStart: CMTime {
			return crossfade.start;
		}
		
		var totalDuration: CMTime {
			return outroPassthrough.end;
		}
	}
	
	func calculateTimeRanges(timeline: AVAssetTrack, video: AVAssetTrack, outro: AVAssetTrack?, crossfadeDuration: Double) -> CompositionTimes {
		var times = CompositionTimes();
		
		let overlapDuration = CMTimeMake(1, CMTimeScale(timeline.nominalFrameRate));
		let overlapStart = CMTimeSubtract(timeline.timeRange.end, overlapDuration);
		
		times.timelinePassthrough = CMTimeRangeMake(kCMTimeZero, overlapStart);
		times.overlap = CMTimeRangeMake(overlapStart, overlapDuration);
		
		let videoEnd = CMTimeAdd(overlapStart, video.timeRange.duration);
		let crossfade = CMTimeMakeWithSeconds(crossfadeDuration, video.timeRange.start.timescale);
		let crossfadeStart = CMTimeSubtract(videoEnd, crossfade);
		
		times.videoPassthrough = CMTimeRangeMake(times.overlap.end, CMTimeSubtract(crossfadeStart, times.overlap.end));
		times.crossfade = CMTimeRangeMake(crossfadeStart, crossfade);
		
		if let `outro` = outro {
			times.outroPassthrough = CMTimeRangeMake(times.crossfade.end, CMTimeSubtract(outro.timeRange.duration, crossfade));
		}

		return times;
	}
}
