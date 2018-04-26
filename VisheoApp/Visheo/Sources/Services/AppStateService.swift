//
//  AppStateService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Reachability

protocol AppStateService {
    var firstLaunch : Bool { get }
    
    var shouldShowOnboarding : Bool { get }
    func onboarding(wasSeen seen: Bool)
	
    var shouldShowOnboardingCover : Bool { get }
    func onboardingCover(wasSeen seen: Bool)
    
    var shouldShowOnboardingShare : Bool { get }
    func onboardingShare(wasSeen seen: Bool)
    
	var shouldShowCameraTips: Bool { get }
	func cameraTips(wereSeen seen: Bool);
	
	var appSettings: AppSettings { get }
	
	var isReachable: Bool { get }
}

class VisheoAppStateService: AppStateService {
    private static let onboardingShownKey = "OnboardingScreenWasShown"
    private static let cameraTipsShownKey = "CameraTipsWasShown"
    private static let appWasLaunchedKey = "appWasLaunchedKey"
    private static let onboardingCoverShownKey = "onboardingCoverShownKey"
    private static let onboardingShareShownKey = "onboardingShareShownKey"
    
    let firstLaunch: Bool
	private let reachability = Reachability();
    
    init() {
        firstLaunch = !UserDefaults.standard.bool(forKey: VisheoAppStateService.appWasLaunchedKey)
        UserDefaults.standard.set(true, forKey: VisheoAppStateService.appWasLaunchedKey)
        UserDefaults.standard.synchronize()
		
		try? reachability?.startNotifier();
    }
	
	deinit {
		reachability?.stopNotifier();
	}
	
	var isReachable: Bool {
		guard let connection = reachability?.connection else {
			return true;
		}
		return connection != .none;
	}
    
    var shouldShowOnboarding: Bool {
        return !UserDefaults.standard.bool(forKey: VisheoAppStateService.onboardingShownKey)
    }
    
    func onboarding(wasSeen seen: Bool) {
        UserDefaults.standard.set(seen, forKey: VisheoAppStateService.onboardingShownKey)        
    }
	
    var shouldShowOnboardingCover : Bool {
        return !UserDefaults.standard.bool(forKey: VisheoAppStateService.onboardingCoverShownKey)
    }
    
    func onboardingCover(wasSeen seen: Bool) {
        UserDefaults.standard.set(seen, forKey: VisheoAppStateService.onboardingCoverShownKey)
    }
    
    var shouldShowOnboardingShare: Bool {
        return !UserDefaults.standard.bool(forKey: VisheoAppStateService.onboardingShareShownKey)
    }
    
    func onboardingShare(wasSeen seen: Bool) {
        UserDefaults.standard.set(seen, forKey: VisheoAppStateService.onboardingShareShownKey)
    }
    
	var shouldShowCameraTips: Bool {
		return !UserDefaults.standard.bool(forKey: VisheoAppStateService.cameraTipsShownKey);
	}
	
	func cameraTips(wereSeen seen: Bool) {
		UserDefaults.standard.set(seen, forKey: VisheoAppStateService.cameraTipsShownKey);
		UserDefaults.standard.synchronize();
	}
	
	var appSettings: AppSettings {
		let defaults = AppSettings();
		
		guard let settingsPath = Bundle.main.path(forResource: "app_settings", ofType: "plist") else {
			return defaults;
		}
		
		let settingsURL = URL(fileURLWithPath: settingsPath);
		
		guard let data = try? Data(contentsOf: settingsURL) else {
			return defaults;
		}
		
		let settings = try? PropertyListDecoder().decode(AppSettings.self, from: data);
		
		return settings ?? defaults;
	}
}
