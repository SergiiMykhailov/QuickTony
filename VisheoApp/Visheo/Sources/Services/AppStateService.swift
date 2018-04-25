//
//  AppStateService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Reachability
import Firebase

extension Notification.Name {
    static let freeVisheoAvailableChanged = Notification.Name("freeVisheoAvailableChanged")
    static let couponAvailableChanged = Notification.Name("couponAvailableChanged")
    static let subscriptionAvailableChanged = Notification.Name("subscriptionAvailableChanged")
    static let inviteFriendsAvailableChanged = Notification.Name("inviteFriendsAvailableChanged")
}

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
    
    var isFreeAvailable : Bool {get}
    var isCouponAvailable : Bool {get}
    var isSubscriptionLimited : Bool {get}
    var isInviteFriendsAvailable : Bool {get}
}

class VisheoAppStateService: AppStateService {
    private static let onboardingShownKey = "OnboardingScreenWasShown"
    private static let cameraTipsShownKey = "CameraTipsWasShown"
    private static let appWasLaunchedKey = "appWasLaunchedKey"
    private static let onboardingCoverShownKey = "onboardingCoverShownKey"
    private static let onboardingShareShownKey = "onboardingShareShownKey"
    
    var isFreeAvailable : Bool = false
    var isCouponAvailable : Bool = false
    var isSubscriptionLimited : Bool = false
    var isInviteFriendsAvailable : Bool = false
    
    private var freeVishesReference : DatabaseReference?
    private var subscriptionReference : DatabaseReference?
    private var couponsReference : DatabaseReference?
    private var inviteFriendsReference : DatabaseReference?
    
    let firstLaunch: Bool
	private let reachability = Reachability();
    
    init() {
        firstLaunch = !UserDefaults.standard.bool(forKey: VisheoAppStateService.appWasLaunchedKey)
        UserDefaults.standard.set(true, forKey: VisheoAppStateService.appWasLaunchedKey)
        UserDefaults.standard.synchronize()
		
		try? reachability?.startNotifier()
        startAppConfigObserving()
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
    
    private func startAppConfigObserving(){
        [freeVishesReference, couponsReference, subscriptionReference, inviteFriendsReference].compactMap { $0 }.forEach {
            $0.removeAllObservers()
        }
        
        let appConfigFreeVishesRef = Database.database().reference(withPath: "appConfiguration/isFreeVisheoAvailable")
        freeVishesReference = appConfigFreeVishesRef
        
        appConfigFreeVishesRef.observe(.value) {
            guard let isFreeAvailable = $0.value as? Bool else { self.isFreeAvailable = false; return}
            self.isFreeAvailable = isFreeAvailable
            NotificationCenter.default.post(name: Notification.Name.freeVisheoAvailableChanged, object: self)
        }
        
        let appConfigCouponsRef = Database.database().reference(withPath: "appConfiguration/isCouponAvailable")
        couponsReference = appConfigCouponsRef
        
        appConfigCouponsRef.observe(.value) {
            guard let isCouponAvailable = $0.value as? Bool else { self.isCouponAvailable = false; return}
            self.isCouponAvailable = isCouponAvailable
            NotificationCenter.default.post(name: Notification.Name.couponAvailableChanged, object: self)
        }
        
        let appConfigSubscriptionRef = Database.database().reference(withPath: "appConfiguration/isSubscriptionLimited")
        subscriptionReference = appConfigSubscriptionRef
        
        appConfigSubscriptionRef.observe(.value) {
            guard let isSubscriptionLimited = $0.value as? Bool else { self.isSubscriptionLimited = false; return}
            self.isSubscriptionLimited = isSubscriptionLimited
            NotificationCenter.default.post(name: Notification.Name.subscriptionAvailableChanged, object: self)
        }
        
        let appConfigInviteFriendsRef = Database.database().reference(withPath: "appConfiguration/isInviteFriendsAvailable")
        inviteFriendsReference = appConfigInviteFriendsRef
        
        appConfigInviteFriendsRef.observe(.value) {
            guard let isInviteFriendsAvailble = $0.value as? Bool else { self.isInviteFriendsAvailable = false; return}
            self.isInviteFriendsAvailable = isInviteFriendsAvailble
            NotificationCenter.default.post(name: Notification.Name.inviteFriendsAvailableChanged, object: self)
        }
    }
}
