//
//  VisheoMovieWriter.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import GPUImage
import Foundation

final class VisheoMovieWriter: GPUImageMovieWriter
{
	private let queue = DispatchQueue(label: "com.visheo.writer.queue", attributes: .concurrent)
	private var allowsAudioRecording = false;
	private var canRecordAudio: Bool {
		get {
			var allow: Bool = false;
			queue.sync {
				allow = self.allowsAudioRecording;
			}
			return allow;
		}
		set {
			queue.async(flags: .barrier) {
				self.allowsAudioRecording = newValue;
			}
		}
	}
	
	
	override func processAudioBuffer(_ audioBuffer: CMSampleBuffer!) {
		if !canRecordAudio {
			return;
		}
		super.processAudioBuffer(audioBuffer);
	}
	
	
	convenience init(url: URL, size: CGSize, fileType: AVFileType = .mov, outputSettings: [String: Any]? = nil) {
		self.init(movieURL: url, size: size, fileType: fileType.rawValue, outputSettings: outputSettings);
		
		let pixelBufferKey = "assetWriterPixelBufferInput";
		let videoInputKey = "assetWriterVideoInput";
		let assetWriterKey = "assetWriter"
		
		guard let pixelBufferAdapter = value(forKey: pixelBufferKey) as? AVAssetWriterInputPixelBufferAdaptor,
			let videoInput = value(forKey: videoInputKey) as? AVAssetWriterInput,
			let assetWriter = value(forKey: assetWriterKey) as? AVAssetWriter else {
			return;
		}
		
		let overrideInput = AVAssetWriterInput(mediaType: videoInput.mediaType, outputSettings: videoInput.outputSettings);
		overrideInput.expectsMediaDataInRealTime = videoInput.expectsMediaDataInRealTime;
		
		let overrideAdapter = VisheoPixelBufferAdaptor(assetWriterInput: overrideInput, sourcePixelBufferAttributes: pixelBufferAdapter.sourcePixelBufferAttributes);
		
		overrideAdapter.didAppendSampleBuffer = { [weak self] in
			self?.canRecordAudio = true;
		}
		
		guard assetWriter.canAdd(overrideInput) else {
			return;
		}
		
		assetWriter.add(overrideInput);
		
		setValue(overrideAdapter, forKey: pixelBufferKey);
		setValue(overrideInput, forKey: videoInputKey);
	}
	
	
	override func startRecording() {
		canRecordAudio = false;
		super.startRecording();
	}
}
