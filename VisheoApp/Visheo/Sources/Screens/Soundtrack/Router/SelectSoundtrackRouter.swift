//
//  SelectSoundtrackRouter.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SelectSoundtrackRouter: FlowRouter
{
	func goBack(with assets: VisheoRenderingAssets)
}

class VisheoSelectSoundtrackRouter: SelectSoundtrackRouter
{
	let dependencies: RouterDependencies
	private(set) weak var controller: UIViewController?
	private(set) weak var viewModel: SelectSoundtrackViewModel?
	private let trackSelectedCallback  : ((VisheoRenderingAssets)->())?
	
	let occasion : OccasionRecord
	let assets: VisheoRenderingAssets
	
	public init(dependencies: RouterDependencies, occasion: OccasionRecord, assets: VisheoRenderingAssets, callback: ((VisheoRenderingAssets)->())? = nil) {
		self.dependencies = dependencies
		self.occasion = occasion
		self.assets = assets
		self.trackSelectedCallback = callback
	}
	
	func start(with viewController: SelectSoundtrackViewController) {
		let vm = VisheoSelectSoundtrackViewModel(occasion: self.occasion, assets: assets,
												 soundtracksService: dependencies.soundtracksService,
												 loggingService: dependencies.loggingService)
		viewModel = vm
		vm.router = self
		self.controller = viewController
		viewController.configure(viewModel: vm, router: self)
	}
	
	
	func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
	}
}


extension VisheoSelectSoundtrackRouter
{
	func goBack(with assets: VisheoRenderingAssets) {
		trackSelectedCallback?(assets);
		controller?.dismiss(animated: true, completion: nil);
	}
}
