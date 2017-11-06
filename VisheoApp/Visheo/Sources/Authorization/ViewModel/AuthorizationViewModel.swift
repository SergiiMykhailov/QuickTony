//
//  AuthorizationViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol AuthorizationViewModel : LongFailableActionViewModel {
    func loginWithGoogle()
    func loginWithFacebook()
    func loginAsAnonymous()
    
    func signIn()
    func signUp()
    
    var getPresentationViewController : (() -> (UIViewController?))? {get set}
}

class VisheoAutorizationViewModel : AuthorizationViewModel {
    var warningAlertHandler: ((String) -> ())?
    var getPresentationViewController: (() -> (UIViewController?))?
    var showProgressCallback: ((Bool) -> ())?
    
    weak var router: AuthorizationRouter?
    var authService : AuthorizationService
    
    init(authService: AuthorizationService) {
        self.authService = authService
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
