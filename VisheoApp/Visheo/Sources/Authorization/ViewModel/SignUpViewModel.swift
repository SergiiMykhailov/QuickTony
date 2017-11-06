//
//  SignUpViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase //TODO: REMOVE

protocol SignUpViewModel : LongFailableActionViewModel {
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
    
    init(userInputValidator: UserInputValidator, authService: AuthorizationService) {
        self.authService = authService
        self.validator = userInputValidator
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoSignUpViewModel.processLogin), name: .userLoggedIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoSignUpViewModel.processLoginFail(notification:)), name: .userLoginFailed, object: nil)
    }
    
    func signUp() {
        self.showProgressCallback?(true)
        authService.signUp(with: email, password: password, fullName: fullName)
    }
    
    @objc func processLogin() {
        self.showProgressCallback?(false)
        self.router?.showMainScreen()
    }
    
    @objc func processLoginFail(notification: Notification) {
        self.showProgressCallback?(false)
        if case .unknownError(let description)? = notification.userInfo?[Notification.Keys.error] as? LoginError {
            self.warningAlertHandler?(description)
        }
    }
}
