//
//  ShareVisheoOnboardingControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 3/29/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol ShareVisheoOnboardingViewModel: class {
    func okButtonTapped()
}

final class ShareVisheoOnboardingControllerViewModel: ShareVisheoOnboardingViewModel {

    // MARK: - Private properties -
    private(set) weak var router: ShareOnboardingRouter?
    private(set) var appStateService: AppStateService

    // MARK: - Lifecycle -

    init(appStateService: AppStateService,
         router: ShareOnboardingRouter) {
        self.appStateService = appStateService
        self.router = router
    }
    
    func okButtonTapped() {
        appStateService.onboardingShare(wasSeen: true)
        self.router?.showShareVisheo()
    }
}
