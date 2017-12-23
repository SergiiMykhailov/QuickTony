//
//  SignInViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol SignInViewModel : class, ProgressGenerating, WarningAlertGenerating {    
    var email : String {get set}
    var password : String {get set}
    
    var canSignIn : Bool {get}
    
    var didChangeCallback : (()->())? {get set}
    
    func signIn()
    
    func forgotPassword(for email: String)
    func canSendForgotPassword(to email: String) -> Bool
    var didSendForgotPasswordCallback : (()->())? {get set}
}

class VisheoSignInViewModel : SignInViewModel {
    var didSendForgotPasswordCallback: (() -> ())?
    
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
		if email.isEmpty {
			warningAlertHandler?(NSLocalizedString("Email is mandatory field", comment: "Missing email warning"))
			return
		}
		
		if !validator.isValid(email: email) {
			warningAlertHandler?(NSLocalizedString("It does not look like a proper email", comment: "Invalid email warning"))
			return
		}
		
		if !validator.isValid(password: password) {
			warningAlertHandler?(NSLocalizedString("Password should be at least 6 symbols", comment: "Invalid password warning"))
			return
		}
		
        showProgressCallback?(true)
        startAuthObserving()
        authService.signIn(with: email, password: password)
    }
    
    func canSendForgotPassword(to email: String) -> Bool {
        return validator.isValid(email:email)
    }
    
    func forgotPassword(for email: String) {
        showProgressCallback?(true)
        
        authService.sendResetPassword(for: email) {[weak self] (error) in
            self?.showProgressCallback?(false)
            if case .unknownError(let description)? = error {
                self?.warningAlertHandler?(description)
            } else {
                self?.didSendForgotPasswordCallback?()
            }
        }
    }
    
    @objc func processLogin() {
        showProgressCallback?(false)
        stopAuthObserving()
        router?.showMainScreen()
    }
    
    @objc func processLoginFail(notification: Notification) {
        showProgressCallback?(false)
        stopAuthObserving()
        if case .unknownError(let description)? = notification.userInfo?[Notification.Keys.error] as? AuthError {
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
