//
//  TipsRouter.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol TipsRouter: FlowRouter {

}

class VisheoTipsRouter: TipsRouter
{
	var dependencies: RouterDependencies
	private(set) weak var controller: UIViewController?
	private(set) weak var viewModel: TipsViewModel?

	init(dependencies: RouterDependencies) {
		self.dependencies = dependencies;
	}
	
	func start(with viewController: TipsViewController) {
		let vm = VisheoTipsViewModel(tipsProvider: dependencies.tipsProviderService);
		viewModel = vm
		vm.router = self
		self.controller = viewController
		viewController.configure(viewModel: vm, router: self)
	}
	
	func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		
	}
}

extension VisheoTipsRouter {
	
}
