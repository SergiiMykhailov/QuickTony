//
//  CameraPermissionsViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/18/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation
import UIKit

protocol CameraPermissionsViewModel: class {
	func requestPermissions()
}


class VisheoCameraPermissionsViewModel: CameraPermissionsViewModel
{
	weak var router: CameraPermissionsRouter?
	
	func requestPermissions()
	{
		if pending.isEmpty && denied.isEmpty {
			showCameraScreen();
			return;
		}
		
		if pending.isEmpty {
			UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!);
			return;
		}
		
		for type in permissions {
			AVCaptureDevice.requestAccess(for: type, completionHandler: { [weak self] _ in
				self?.handlePermissionsChange();
			});
		}
	}
	
	//MARK: - Helpers

	private var permissions: [AVMediaType] {
		return [.video, .audio];
	}
	
	private var pending: [AVMediaType] {
		return permissions.filter{ AVCaptureDevice.authorizationStatus(for: $0) == .notDetermined };
	}
	
	private var denied: [AVMediaType] {
		return permissions.filter{ [.restricted, .denied].contains(AVCaptureDevice.authorizationStatus(for: $0)) }
	}
	
	private func showCameraScreen() {
		DispatchQueue.main.async {
			self.router?.showCameraScreen();
		}
	}
	
	private func handlePermissionsChange() {
		if pending.isEmpty && denied.isEmpty {
			showCameraScreen();
			return;
		}
	}
}
