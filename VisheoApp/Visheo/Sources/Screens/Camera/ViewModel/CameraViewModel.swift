//
//  CameraViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation
import GPUImage


enum CameraRecordingState
{
	case countdown(value: String)
	case recording
	case stopped(error: Error?)
}


enum RecordingError: Error
{
	case userStopped
}


private let maxVideoRecordingDuration: TimeInterval = 30.0;


protocol CameraViewModel: class
{
	var shouldPresentCameraTips: Bool { get };
	func markCameraTipsSeen();
	
	var isRecording: Bool { get }
	
	var recordingStateChangedBlock: ((CameraRecordingState) -> Void)? { get set };
	var recordingProgressChangedBlock: ((Double) -> Void)? { get set }
	
	func addPreviewOutput(_ output: GPUImageInput)
	func startCapture()
	func stopCapture();
	func toggleRecording()
	func toggleCameraFace();
}


class VisheoCameraViewModel: NSObject, CameraViewModel
{
	var appState : AppStateService
	
	weak var router: CameraRouter?
	var recordingStateChangedBlock: ((CameraRecordingState) -> Void)? = nil;
	var recordingProgressChangedBlock: ((Double) -> Void)? = nil;
	
	private let cropFilter = GPUImageCropFilter();
	
	private var camera: GPUImageVideoCamera?;
	private var movieWriter: GPUImageMovieWriter?;
	private (set) var isRecording = false;
	
	private var countdownTimer: Timer? = nil;
	private var outputVideoSize = CGSize(width: 480.0, height: 480.0);
	private var displayLink: CADisplayLink? = nil;
	
    private let assets : VisheoRenderingAssets
	
	init(appState: AppStateService, assets : VisheoRenderingAssets) {
		self.appState = appState;
        self.assets = assets
		super.init();
	}
	
	
	func addPreviewOutput(_ output: GPUImageInput) {
		cropFilter.addTarget(output);
	}
	
	//MARK: - Recording
	
	func startCapture() {
		camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.high.rawValue, cameraPosition: .front);
		camera?.outputImageOrientation = .portrait;
		camera?.delegate = self;
		camera?.horizontallyMirrorFrontFacingCamera = true;
		
		camera?.addTarget(cropFilter);
		camera?.startCapture();
	}
	
	
	func toggleRecording() {
		if isRecording {
			finishRecording();
		} else {
			startRecording();
		}
	}
	
	
	func stopCapture() {
		if isRecording {
			finishRecording(error: RecordingError.userStopped);
		}
		camera?.stopCapture();
	}
	
	
	private func startRecording() {
		
		isRecording = true;
		
		do
		{
			let url = assets.videoUrl;
			
			movieWriter = GPUImageMovieWriter(movieURL: url, size: outputVideoSize);
			movieWriter?.encodingLiveVideo = true;
			movieWriter?.hasAudioTrack = true;
			
			movieWriter?.failureBlock = { [weak self] error in
				self?.finishRecording(error: error);
			}
			
			var countdownValue = 3;
			
			recordingStateChangedBlock?(.countdown(value: "\(countdownValue)"));
			
			countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] (timer) in
				
				countdownValue -= 1;
				
				if countdownValue > 0 {
					self?.recordingStateChangedBlock?(.countdown(value: "\(countdownValue)"));
				} else {
					self?.startWriting();
				}
			}
			
			RunLoop.main.add(countdownTimer!, forMode: .commonModes);
		}
		catch (let error) {
			finishRecording(error: error);
		}
	}
	
	
	private func startWriting() {
		
		countdownTimer?.invalidate();
		
		displayLink = CADisplayLink(target: self, selector: #selector(VisheoCameraViewModel.updateRecordingDuration));
		displayLink?.add(to: RunLoop.main, forMode: .commonModes);
		
		cropFilter.addTarget(movieWriter);
		movieWriter?.startRecording();
			
		recordingStateChangedBlock?(.recording);
	}
	
	
	private func finishRecording(error: Error? = nil) {
		
		countdownTimer?.invalidate();
		displayLink?.invalidate();
		
		isRecording = false;
		
		let finalize: ((Error?) -> Void) = { [weak self] error in
			guard let `self` = self else { return }
			
			self.recordingProgressChangedBlock?(0.0);
			self.recordingStateChangedBlock?(.stopped(error: error));
			self.cropFilter.removeTarget(self.movieWriter)
			self.movieWriter = nil;
		}
		
		if let e = error {
			finalize(e);
			return;
		}
		
		guard let writer = movieWriter else {
			finalize(nil);
			return;
		}
		
//        let url = writer.assetWriter.outputURL;
		
		writer.finishRecording(completionHandler: { [weak self] in
			finalize(nil);
            if let strongSelf = self {
                DispatchQueue.main.async {
                    strongSelf.router?.showTrimScreen(with: strongSelf.assets)
                }
            }
		});
	}
	
	@objc func updateRecordingDuration()
	{
		let duration = movieWriter?.duration ?? kCMTimeZero;
		let seconds = CMTimeGetSeconds(duration);
		let progress = seconds / maxVideoRecordingDuration;
		
		if progress >= 1.0 {
			finishRecording();
		} else {
			recordingProgressChangedBlock?(progress);
		}
	}
	
	
	func toggleCameraFace() {
		camera?.rotateCamera();
	}
	
	
	var shouldPresentCameraTips: Bool {
		return appState.shouldShowCameraTips;
	}
	
	
	func markCameraTipsSeen() {
		appState.cameraTips(wereSeen: true);
	}
}


extension VisheoCameraViewModel: GPUImageVideoCameraDelegate
{
	func willOutputSampleBuffer(_ sampleBuffer: CMSampleBuffer!)
	{
		guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
			return;
		}
		
		let sessionWidth = Double(CVPixelBufferGetWidth(imageBuffer));
		let sessionHeight = Double(CVPixelBufferGetHeight(imageBuffer));
		
		let width = min(sessionWidth, sessionHeight);
		let height = max(sessionWidth, sessionHeight);
		
		let minDimension = width;
		
		outputVideoSize = CGSize(width: minDimension, height: minDimension);
		
		var offsetX = 0.0;
		var offsetY = 0.0;
		
		let croppedWidth = minDimension / width;
		let croppedHeight = minDimension / height;
		
		if croppedWidth < 1.0 {
			offsetX = (1.0 - croppedWidth) / 2.0;
		}
		
		if croppedHeight < 1.0 {
			offsetY = (1.0 - croppedHeight) / 2.0;
		}
		
		let cropRect = CGRect(x: offsetX, y: offsetY, width: croppedWidth, height: croppedHeight);
		
		if !cropFilter.cropRegion.equalTo(cropRect) {
			cropFilter.cropRegion = cropRect;
		}
	}
}


extension CameraRecordingState: Equatable
{
	static func ==(lhs: CameraRecordingState, rhs: CameraRecordingState) -> Bool
	{
		switch (lhs, rhs)
		{
		case (.stopped, .stopped):
			return true;
		case (.recording, .recording):
			return true;
		case (.countdown, .countdown):
			return true;
		default:
			return false;
		}
	}
}
