//
//  OnboardingViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol OnboardingViewModel : class {
    func onBoardingSeen()
}

class VisheoOnboardingViewModel : OnboardingViewModel {
    weak var router: OnboardingRouter?
    var appState : AppStateService
    
    init(appState: AppStateService) {
        self.appState = appState
    }
    
    func onBoardingSeen() {
        appState.onboarding(wasSeen: true)
        
        router?.showLogin()
    }
}
