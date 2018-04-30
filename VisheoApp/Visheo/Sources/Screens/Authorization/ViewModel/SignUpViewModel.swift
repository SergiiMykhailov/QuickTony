//
//  SignUpViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol SignUpViewModel : class, ProgressGenerating, WarningAlertGenerating {
    var email : String {get set}
    var fullName : String {get set}
    var password : String {get set}
    
    var canSignUp : Bool {get}
    
    var didChangeCallback : (()->())? {get set}
    
    func signUp()
}

class VisheoSignUpViewModel : SignUpViewModel {
    var didChangeCallback: (() -> ())? {
        didSet {
            didChangeCallback?()
        }
    }
    
    var showProgressCallback: ((Bool) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var canSignUp: Bool {
        let emailValid = validator.isValid(email: email)
        let passwordValid = validator.isValid(password: password)
        let usernameValid = validator.isValid(username: fullName)
        return passwordValid && emailValid && usernameValid
    }
    
    var email: String = "" {
        didSet {
            didChangeCallback?()
        }
    }
    
    var fullName: String = "" {
        didSet {
            didChangeCallback?()
        }
    }
    
    var password: String = "" {
        didSet {
            didChangeCallback?()
        }
    }
    
    weak var router: SignUpRouter?
    
    let validator : UserInputValidator
    var authService : AuthorizationService
    let userNotificationService: UserNotificationsService
    
    init(userInputValidator: UserInputValidator, authService: AuthorizationService, userNotificationService: UserNotificationsService) {
        self.authService = authService
        self.validator = userInputValidator
        self.userNotificationService = userNotificationService
    }
    
    func signUp() {
        if fullName.isEmpty {
            warningAlertHandler?(NSLocalizedString("Name is mandatory field", comment: "Missing name warning"))
            return
        }

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
        authService.signUp(with: email, password: password, fullName: fullName)
    }
    
    @objc func processLogin() {
        showProgressCallback?(false)
        stopAuthObserving()
        router?.showMainScreen()
        
        if (!authService.isAnonymous) {
            userNotificationService.registerNotifications()
        }
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
