//
//  CameraRouter.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


protocol CameraRouter: FlowRouter {
	func showTrimScreen(with assets: VisheoRenderingAssets)
}


class VisheoCameraRouter: CameraRouter
{
	enum SegueList: String, SegueListType {
		case showTrimScreen = "showTrimScreen"
	}
	
	let dependencies: RouterDependencies
	private(set) weak var controller: UIViewController?
	private(set) weak var viewModel: CameraViewModel?
    let assets : VisheoRenderingAssets

    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets) {
		self.dependencies = dependencies
        self.assets = assets
	}
	
	func start(with viewController: CameraViewController) {
        let vm = VisheoCameraViewModel(appState: dependencies.appStateService, assets: self.assets);
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
        case .showTrimScreen:
            let trimmingController = segue.destination as! VideoTrimmingViewController
            let trimmingRouter = VisheoVideoTrimmingRouter(dependencies: dependencies, assets: assets)
            trimmingRouter.start(with: trimmingController)
		}
	}
}


extension VisheoCameraRouter {
    func showTrimScreen(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showTrimScreen, sender: assets)
    }
}
