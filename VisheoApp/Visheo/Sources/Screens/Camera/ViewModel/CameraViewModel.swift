//
//  CameraViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation
import GPUImage


enum CameraReadiness
{
	case ready
	case needsPermissions(enableViaSettings: Bool)
}


enum CameraRecordingState
{
	case countdown(value: Int)
	case recording
	case stopped
}


protocol CameraViewModel: class
{
	var isRecording: Bool { get }
	
	var recordingStateChangedBlock: ((CameraRecordingState) -> Void)? { get set };
	var cameraReadinessChangeBlock: ((CameraReadiness) -> Void)? { get set };
	
	func addPreviewOutput(_ output: GPUImageInput)
	func prepareCamera()
	func toggleRecording()
	func toggleCameraFace();
}


class VisheoCameraViewModel: NSObject, CameraViewModel, GPUImageVideoCameraDelegate
{
	weak var router: CameraRouter?
	var recordingStateChangedBlock: ((CameraRecordingState) -> Void)? = nil;
	var cameraReadinessChangeBlock: ((CameraReadiness) -> Void)? = nil;
	
	private let cropFilter = GPUImageCropFilter();
	
	private var camera: GPUImageVideoCamera?;
	private var movieWriter: GPUImageMovieWriter?;
	private (set) var isRecording = false;
	
	
	func prepareCamera()
	{
		if canStartCamera {
			createCamera();
			return;
		}
		
		let hasDeniedPermissions = !deniedPermissions.isEmpty;
		cameraReadinessChangeBlock?(.needsPermissions(enableViaSettings: hasDeniedPermissions));
		
//		guard !pendingPermissions.isEmpty else {
//			return;
//		}
//
//		for type in pendingPermissions {
//			AVCaptureDevice.requestAccess(for: type, completionHandler: { [weak self] _ in
//				self?.handlePermissionsUpdate();
//			});
//		}
	}
	
	
	private func createCamera()
	{
		camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.high.rawValue, cameraPosition: .front);
		camera?.outputImageOrientation = .portrait;
		camera?.delegate = self;
		camera?.horizontallyMirrorFrontFacingCamera = true;
		
		camera?.addTarget(cropFilter);
		camera?.startCapture();
		
		cameraReadinessChangeBlock?(.ready);
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
	
	
	func toggleCameraFace()
	{
		camera?.rotateCamera();
	}
	
	
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


//MARK: - Permissions handling

fileprivate extension VisheoCameraViewModel
{
	private func handlePermissionsUpdate()
	{
		if canStartCamera {
			createCamera();
		} else {
			let hasDeniedPermissions = !deniedPermissions.isEmpty;
			cameraReadinessChangeBlock?(.needsPermissions(enableViaSettings: hasDeniedPermissions));
		}
	}
	
	private var canStartCamera: Bool {
		return pendingPermissions.isEmpty && deniedPermissions.isEmpty;
	}
	
	
	private var necessaryMedia: [AVMediaType] {
		return [.video, .audio];
	}
	
	
	private var pendingPermissions: [AVMediaType] {
		return necessaryMedia.filter{ AVCaptureDevice.authorizationStatus(for: $0) == .notDetermined }
	}
	
	
	private var deniedPermissions: [AVMediaType] {
		return necessaryMedia.filter{ return [.denied, .restricted].contains(AVCaptureDevice.authorizationStatus(for: $0)) }
	}
}
