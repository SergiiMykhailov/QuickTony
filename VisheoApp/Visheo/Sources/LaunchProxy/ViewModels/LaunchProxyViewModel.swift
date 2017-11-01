//
//  LaunchProxyViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

class LaunchProxyViewModel {
    private static let onboardingShownKey = "OnboardingScreenWasShown"
    
    private let userDefaults : UserDefaults
    
    weak var router: LaunchProxyRouter?
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }
    
    func launch() {
        if !userDefaults.bool(forKey: LaunchProxyViewModel.onboardingShownKey) {
            router?.showOnboarding()
        }
    }
}

