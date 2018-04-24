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
    var loggingService : EventLoggingService
    
    init(appState: AppStateService, eventLoggingService: EventLoggingService) {
        self.appState = appState
        self.loggingService = eventLoggingService
    }
    
    func onBoardingSeen() {
        appState.onboarding(wasSeen: true)
        loggingService.log(event: BestPracticesClicked())
        
        router?.showLogin()
    }
}
