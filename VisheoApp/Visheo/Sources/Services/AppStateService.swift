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
	
	var shouldShowCameraTips: Bool { get }
	func cameraTips(wereSeen seen: Bool);
}

class VisheoAppStateService: AppStateService {
	
    private static let onboardingShownKey = "OnboardingScreenWasShown"
	private static let cameraTipsShownKey = "CameraTipsWasShown"

    var shouldShowOnboarding: Bool {
        return !UserDefaults.standard.bool(forKey: VisheoAppStateService.onboardingShownKey)
    }
    
    func onboarding(wasSeen seen: Bool) {
        UserDefaults.standard.set(seen, forKey: VisheoAppStateService.onboardingShownKey)
        UserDefaults.standard.synchronize()
    }
	
	var shouldShowCameraTips: Bool {
		return !UserDefaults.standard.bool(forKey: VisheoAppStateService.cameraTipsShownKey);
	}
	
	func cameraTips(wereSeen seen: Bool) {
		UserDefaults.standard.set(seen, forKey: VisheoAppStateService.cameraTipsShownKey);
		UserDefaults.standard.synchronize();
	}
}
