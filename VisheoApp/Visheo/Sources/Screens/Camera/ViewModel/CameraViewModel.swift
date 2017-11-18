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
	case countdown(value: Int)
	case recording
	case stopped
}


protocol CameraViewModel: class
{
	var shouldPresentCameraTips: Bool { get };
	func markCameraTipsSeen();
	
	var isRecording: Bool { get }
	
	var recordingStateChangedBlock: ((CameraRecordingState) -> Void)? { get set };
	
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
	
	private let cropFilter = GPUImageCropFilter();
	
	private var camera: GPUImageVideoCamera?;
	private var movieWriter: GPUImageMovieWriter?;
	private (set) var isRecording = false;
	
	
	init(appState: AppStateService)
	{
		self.appState = appState;
		super.init();
	}
	
	
	func startCapture()
	{
		camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.high.rawValue, cameraPosition: .front);
		camera?.outputImageOrientation = .portrait;
		camera?.delegate = self;
		camera?.horizontallyMirrorFrontFacingCamera = true;
		
		camera?.addTarget(cropFilter);
		camera?.startCapture();
	}
	
	
	func addPreviewOutput(_ output: GPUImageInput) {
		cropFilter.addTarget(output);
	}
	
	
	func toggleRecording()
	{
		if isRecording {
			finishRecording();
		} else {
			startRecording();
		}
	}
	
	
	func stopCapture()
	{
		if isRecording {
			finishRecording();
		}
		
		camera?.stopCapture();
	}
	
	
	private func startRecording()
	{
		isRecording = true;
		
		recordingStateChangedBlock?(.recording);
		
//		movieWriter?.startRecording();
	}
	
	private func finishRecording()
	{
		isRecording = false;
		
		recordingStateChangedBlock?(.stopped);
		
//		movieWriter?.finishRecording(completionHandler: { [weak self] in
//			self?.recordingStateChangedBlock?(.stopped);
//		});
	}
	
	func toggleCameraFace() {
		camera?.rotateCamera();
	}
	
	var shouldPresentCameraTips: Bool {
		return true; appState.shouldShowCameraTips;
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
