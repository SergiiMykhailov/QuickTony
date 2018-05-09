//
//  PrompterOnboardingControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 5/2/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol PrompterOnboardingViewModel: class {
    func goBack()
}

final class PrompterOnboardingControllerViewModel: PrompterOnboardingViewModel {
    private var appStateService: AppStateService
    
    // MARK: - Private properties -
    private(set) weak var router: PrompterOnboardingRouter?

    // MARK: - Lifecycle -

    init(router: PrompterOnboardingRouter, appStateService: AppStateService) {
        self.router = router
        self.appStateService = appStateService
    }

    func goBack() {
        appStateService.prompterOnboarding(wasSeen: true)
    }
}
