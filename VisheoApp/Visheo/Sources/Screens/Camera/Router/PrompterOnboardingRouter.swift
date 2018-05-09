//
//  PrompterOnboardingRouter.swift
//  Visheo
//
//  Created by Ivan on 5/2/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol PrompterOnboardingRouter: FlowRouter {
}

class DefaultPrompterOnboardingRouter:  PrompterOnboardingRouter {
    var dependencies: RouterDependencies

    private(set) weak var viewModel: PrompterOnboardingViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for orgSegue: UIStoryboardSegue, sender: Any?) {
    }

    init(withDependencies dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(with controller: PrompterOnboardingViewController) {
        self.controller = controller
        let vm = PrompterOnboardingControllerViewModel(router: self, appStateService: dependencies.appStateService)
        viewModel = vm
        controller.configure(viewModel: vm, router: self)
    }
}
