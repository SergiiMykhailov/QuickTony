//
//  CameraViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation
import GPUImage


enum CameraScreenPresentation
{
	case camera
	case permissions
}


protocol CameraViewModel: class
{
	var screenPresentation: CameraScreenPresentation { get }
	
	func addPreviewOutput(_ output: GPUImageInput)
	func prepareCamera()
}


class VisheoCameraViewModel: NSObject, CameraViewModel, GPUImageVideoCameraDelegate
{
	weak var router: CameraRouter?
	
	private let cropFilter = GPUImageCropFilter();
	
	private var camera: GPUImageVideoCamera?;
	private var movieWriter: GPUImageMovieWriter?;
	
	
	var screenPresentation: CameraScreenPresentation {
		return canStartCamera ? .camera : .permissions;
	}
	
	
	func prepareCamera()
	{
		if canStartCamera {
			createCamera();
			return;
		}
		
		for type in pendingPermissions {
			AVCaptureDevice.requestAccess(for: type, completionHandler: { [weak self] _ in
				self?.handlePermissionsUpdate();
			});
		}
	}
	
	
	private func createCamera()
	{
		camera = GPUImageVideoCamera(sessionPreset: AVCaptureSession.Preset.high.rawValue, cameraPosition: .front);
		camera?.outputImageOrientation = .portrait;
		camera?.delegate = self;
		camera?.horizontallyMirrorFrontFacingCamera = true;
		
		camera?.addTarget(cropFilter);
		camera?.startCapture();
	}
	
	
	private func handlePermissionsUpdate()
	{
		if canStartCamera {
			createCamera();
			return;
		}
	}
	
	
	func addPreviewOutput(_ output: GPUImageInput) {
		cropFilter.addTarget(output);
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


fileprivate extension VisheoCameraViewModel
{
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
