//
//  AppStateService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol AppStateService {
    var firstLaunch : Bool { get }
    
    var shouldShowOnboarding : Bool { get }
    func onboarding(wasSeen seen: Bool)
	
	var shouldShowCameraTips: Bool { get }
	func cameraTips(wereSeen seen: Bool);
}

class VisheoAppStateService: AppStateService {
    private static let onboardingShownKey = "OnboardingScreenWasShown"
    private static let cameraTipsShownKey = "CameraTipsWasShown"
    private static let appWasLaunchedKey = "appWasLaunchedKey"
    
    let firstLaunch: Bool
    
    init() {
        firstLaunch = !(UserDefaults.standard.bool(forKey: VisheoAppStateService.appWasLaunchedKey) ?? false)
        UserDefaults.standard.set(true, forKey: VisheoAppStateService.appWasLaunchedKey)
        UserDefaults.standard.synchronize()
    }
    
    var shouldShowOnboarding: Bool {
        return !UserDefaults.standard.bool(forKey: VisheoAppStateService.onboardingShownKey)
    }
    
    func onboarding(wasSeen seen: Bool) {
        UserDefaults.standard.set(seen, forKey: VisheoAppStateService.onboardingShownKey)        
    }
	
	var shouldShowCameraTips: Bool {
		return !UserDefaults.standard.bool(forKey: VisheoAppStateService.cameraTipsShownKey);
	}
	
	func cameraTips(wereSeen seen: Bool) {
		UserDefaults.standard.set(seen, forKey: VisheoAppStateService.cameraTipsShownKey);
		UserDefaults.standard.synchronize();
	}
}
