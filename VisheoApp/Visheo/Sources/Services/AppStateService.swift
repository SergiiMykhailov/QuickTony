//
//  AppStateService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol AppStateService {
    var shouldShowOnboarding : Bool { get }
    func onboarding(wasSeen seen: Bool)
}

class VisheoAppStateService: AppStateService {
    
    private static let onboardingShownKey = "OnboardingScreenWasShown"

    var shouldShowOnboarding: Bool {
        return !UserDefaults.standard.bool(forKey: VisheoAppStateService.onboardingShownKey)
    }
    
    func onboarding(wasSeen seen: Bool) {
        UserDefaults.standard.set(seen, forKey: VisheoAppStateService.onboardingShownKey)
        UserDefaults.standard.synchronize()
    }
    
}
