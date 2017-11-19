//
//  CameraPermissionsRouter.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/18/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol CameraPermissionsRouter: FlowRouter {
	func showCameraScreen()
}


class VisheoCameraPermissionsRouter: CameraPermissionsRouter
{
	enum SegueList: String, SegueListType {
		case next
		case showCameraScreen = "showCameraScreen"
	}
	
	let dependencies: RouterDependencies
	private(set) weak var controller: UIViewController?
	private(set) weak var viewModel: CameraPermissionsViewModel?
	
	
	public init(dependencies: RouterDependencies) {
		self.dependencies = dependencies
	}
	
	func start(with viewController: CameraPermissionsViewController) {
		let vm = VisheoCameraPermissionsViewModel();
		viewModel = vm
		vm.router = self
		self.controller = viewController
		viewController.configure(viewModel: vm, router: self)
	}
	
	func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		guard let segueList = SegueList(segue: segue) else {
			return
		}
		switch segueList {
			case .showCameraScreen:
				let cameraController = segue.destination as! CameraViewController
				let router = VisheoCameraRouter(dependencies: dependencies)
				router.start(with: cameraController)
			default:
				break
		}
	}
}


extension VisheoCameraPermissionsRouter
{
	func showCameraScreen() {
		controller?.performSegue(SegueList.showCameraScreen, sender: nil);
	}
}