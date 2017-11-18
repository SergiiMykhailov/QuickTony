//
//  CameraRouter.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


protocol CameraRouter: FlowRouter {
	func showCropScreen(for movie: URL)
}


class VisheoCameraRouter: CameraRouter
{
	enum SegueList: String, SegueListType {
		case showCropScreen = "showCropScreen"
	}
	
	let dependencies: RouterDependencies
	private(set) weak var controller: UIViewController?
	private(set) weak var viewModel: CameraViewModel?
	

	public init(dependencies: RouterDependencies) {
		self.dependencies = dependencies
	}
	
	func start(with viewController: CameraViewController) {
		let vm = VisheoCameraViewModel(appState: dependencies.appStateService);
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
		default:
			break
		}
	}
}


extension VisheoCameraRouter {
	func showCropScreen(for movie: URL) {
//		controller?.performSegue(SegueList.showCropScreen, sender: movie);
	}
}
