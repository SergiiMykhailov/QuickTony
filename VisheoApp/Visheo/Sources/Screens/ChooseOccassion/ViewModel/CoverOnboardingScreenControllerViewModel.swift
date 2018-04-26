//
//  CoverOnboardingScreenControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 3/29/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol CoverOnboardingScreenViewModel: class {
    func okButtonTapped()
}

final class CoverOnboardingScreenControllerViewModel: CoverOnboardingScreenViewModel {

    // MARK: - Private properties -
    private(set) weak var router: CoverOnboardingScreenRouter?
    private(set) var appStateService: AppStateService
    // MARK: - Lifecycle -

    init(appStateService: AppStateService,
         router: CoverOnboardingScreenRouter) {
        self.appStateService = appStateService
        self.router = router
    }
    
    func okButtonTapped() {
        appStateService.onboardingCover(wasSeen: true)
        self.router?.showSelectCover()
    }

}
