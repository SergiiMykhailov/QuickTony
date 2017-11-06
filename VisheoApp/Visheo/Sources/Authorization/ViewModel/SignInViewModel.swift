//
//  SignInViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol SignInViewModel : LongFailableActionViewModel {
    var email : String {get set}
    var password : String {get set}
    
    var canSignIn : Bool {get}
    
    var didChangeCallback : (()->())? {get set}
    
    func signIn()
}

class VisheoSignInViewModel : SignInViewModel {
    var didChangeCallback: (() -> ())? {
        didSet {
            didChangeCallback?()
        }
    }
    var showProgressCallback: ((Bool) -> ())?
    var warningAlertHandler: ((String) -> ())?
    
    var canSignIn: Bool {
        let emailValid = validator.isValid(email: email)
        let passwordValid = validator.isValid(password: password)
        return passwordValid && emailValid
    }
    
    var email: String = "" {
        didSet {
            didChangeCallback?()
        }
    }
    
    var password: String = "" {
        didSet {
            didChangeCallback?()
        }
    }
    
    weak var router: SignInRouter?
    
    let validator : UserInputValidator
    var authService : AuthorizationService
    
    init(userInputValidator: UserInputValidator, authService: AuthorizationService) {
        self.authService = authService
        self.validator = userInputValidator
    }
    
    func signIn() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.signIn(with: email, password: password)
    }
    
    @objc func processLogin() {
        showProgressCallback?(false)
        stopAuthObserving()
        router?.showMainScreen()
    }
    
    @objc func processLoginFail(notification: Notification) {
        showProgressCallback?(false)
        stopAuthObserving()
        if case .unknownError(let description)? = notification.userInfo?[Notification.Keys.error] as? LoginError {
            warningAlertHandler?(description)
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
