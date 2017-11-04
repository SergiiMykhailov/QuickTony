//
//  SignUpViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase

protocol SignUpViewModel : class {
    var email : String {get set}
    var fullName : String {get set}
    var password : String {get set}
    
    var canSignUp : Bool {get set}
    
    func signUp()
}

class VisheoSignUpViewModel : SignUpViewModel {
    var canSignUp: Bool
    
    func signUp() {
    }
    
    var email: String
    
    var fullName: String
    
    var password: String
    
    weak var router: SignUpRouter?
    
    init() {
    }
}
