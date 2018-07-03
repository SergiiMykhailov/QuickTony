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
    func showPrompterOnboarding()
}


class VisheoCameraRouter: CameraRouter
{
	enum SegueList: String, SegueListType {
		case showTrimScreen = "showTrimScreen"
        case showPrompterView = "showPrompterView"
        case showPrompterOnboarding = "showPrompterOnboarding"
	}
	
	let dependencies: RouterDependencies
	private(set) weak var controller: UIViewController?
	private(set) weak var viewModel: CameraViewModel?
    let assets : VisheoRenderingAssets
    
    private var finishRecordingCallback: ((VisheoRenderingAssets)->())?

    public init(dependencies: RouterDependencies,
                assets: VisheoRenderingAssets,
                finishRecordingCallback: ((VisheoRenderingAssets)->())? = nil) {
		self.dependencies = dependencies
        self.assets = assets
        self.finishRecordingCallback = finishRecordingCallback
	}
	
	func start(with viewController: CameraViewController) {
        let vm = VisheoCameraViewModel(appState: dependencies.appStateService, assets: self.assets, loggingService: dependencies.loggingService);
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
            case .showPrompterView:
                let prompterController = segue.destination as! PrompterViewController
                let words = assets.originalOccasion.words
                let prompterRouter = DefaultPrompterRouter(withDependecies: dependencies)
                prompterRouter.start(with: prompterController, words: words)
            case .showPrompterOnboarding:
                let prompterOnboardingController = segue.destination as! PrompterOnboardingViewController
                let prompterOnboardingRouter = DefaultPrompterOnboardingRouter(withDependencies: dependencies)
                prompterOnboardingRouter.start(with: prompterOnboardingController)
		}
	}
}


extension VisheoCameraRouter {
    func showTrimScreen(with assets: VisheoRenderingAssets) {
        if (finishRecordingCallback != nil) {
            finishRecordingCallback?(assets)
            controller?.navigationController?.popViewController(animated: true)
        } else {
            controller?.performSegue(SegueList.showTrimScreen, sender: assets)
        }
    }
    
    func showPrompterOnboarding() {
        controller?.performSegue(SegueList.showPrompterOnboarding, sender: nil)
    }
}
