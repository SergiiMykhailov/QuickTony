//
//  AuthorizationViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol AuthorizationViewModel : class, ProgressGenerating, WarningAlertGenerating {
    func loginWithGoogle()
    func loginWithFacebook()
    func loginAsAnonymous()
    
    var anonymousAllowed : Bool { get }
    
    func signIn()
    func signUp()
    
    func cancel()
    
    var getPresentationViewController : (() -> (UIViewController?))? {get set}
    
    var cancelAllowed : Bool {get}
    var descriptionString : String? {get}
}

class VisheoAutorizationViewModel : AuthorizationViewModel {
    var cancelAllowed: Bool {
        return authForBuyingPremium
    }
    
    var descriptionString: String? {
        if authForBuyingPremium {
            return NSLocalizedString("Please sign in to purchase premium cards", comment: "Please sign in to purchase premium cards")
        }
        return nil
    }
    
    var warningAlertHandler: ((String) -> ())?
    var getPresentationViewController: (() -> (UIViewController?))?
    var showProgressCallback: ((Bool) -> ())?
    let anonymousAllowed : Bool
    private let authForBuyingPremium : Bool
    
    weak var router: AuthorizationRouter?
    var authService : AuthorizationService
    
    init(authService: AuthorizationService, anonymousAllowed: Bool, authForBuyingPremium: Bool) {
        self.authForBuyingPremium = authForBuyingPremium
        self.authService = authService
        self.anonymousAllowed = anonymousAllowed
    }
    
    deinit {
        stopAuthObserving()
    }
    
    func loginWithGoogle() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.loginWithGoogle(from: getPresentationViewController?())
    }
    
    func loginWithFacebook() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.loginWithFacebook(from: getPresentationViewController?())
    }
    
    func loginAsAnonymous() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.loginAsAnonymous()
    }
    
    func signIn() {
        router?.showSignIn()
    }
    
    func signUp() {
        router?.showSignUp()
    }
    
    func cancel() {
        router?.close()
    }
    
    @objc func processLogin() {
        showProgressCallback?(false)
        stopAuthObserving()
        router?.showMainScreen()
    }
    
    @objc func processLoginFail(notification: Notification) {
        stopAuthObserving()
        self.showProgressCallback?(false)
        if case .unknownError(let description)? = notification.userInfo?[Notification.Keys.error] as? AuthError {
            self.warningAlertHandler?(description)
        }
    }
    
    private func startAuthObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoAutorizationViewModel.processLogin), name: .userLoggedIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoAutorizationViewModel.processLoginFail(notification:)), name: .userLoginFailed, object: nil)
    }
    
    private func stopAuthObserving() {
        NotificationCenter.default.removeObserver(self)
    }
}
