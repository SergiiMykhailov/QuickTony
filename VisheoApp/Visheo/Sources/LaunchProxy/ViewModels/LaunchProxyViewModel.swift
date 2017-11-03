//
//  LaunchProxyViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol LaunchProxyViewModel : class {
    func launch()
}

class VisheoLaunchProxyViewModel : LaunchProxyViewModel {
    private let appState : AppStateService
    private let authService : AuthorizationService
    
    weak var router: LaunchProxyRouter?
    
    init(appState: AppStateService, authService: AuthorizationService) {
        self.appState = appState
        self.authService = authService
    }
    
    func launch() {
        if appState.shouldShowOnboarding {
            router?.showOnboarding()
        } else if self.authService.isAuthorized {
            router?.showMainScreen()
        } else {
            router?.showLogin()
        }
    }
}

