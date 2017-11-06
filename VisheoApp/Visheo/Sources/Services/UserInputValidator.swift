//
//  UserInputValidator.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Validator

protocol UserInputValidator {
    func isValid(email : String) -> Bool
    func isValid(password : String) -> Bool
    func isValid(username : String) -> Bool
}

class VisheoUserInputValidator: UserInputValidator {
    private struct ValidationError : Error {}
    let emailRule : ValidationRulePattern
    let usernameRule : ValidationRuleLength
    let passwordRule : ValidationRuleLength
    init() {
        emailRule = ValidationRulePattern(pattern: EmailValidationPattern.standard, error : ValidationError())
        usernameRule = ValidationRuleLength(min: 1, error: ValidationError())
        passwordRule = ValidationRuleLength(min: 5, error : ValidationError())
    }
    
    func isValid(email: String) -> Bool {
        return email.validate(rule: emailRule) == .valid
    }
    
    func isValid(password: String) -> Bool {
        return password.validate(rule: passwordRule) == .valid
    }
    
    func isValid(username: String) -> Bool {
        return username.validate(rule: usernameRule) == .valid
    }
}


