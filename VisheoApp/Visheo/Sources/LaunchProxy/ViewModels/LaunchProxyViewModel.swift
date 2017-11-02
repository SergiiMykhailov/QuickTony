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
    
    weak var router: LaunchProxyRouter?
    
    init(appState: AppStateService) {
        self.appState = appState
    }
    
    func launch() {
        if appState.shouldShowOnboarding {
            router?.showOnboarding()
        } else {
            router?.showLogin()
        }
    }
}

