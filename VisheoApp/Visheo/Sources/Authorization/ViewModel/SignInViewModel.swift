//
//  SignInViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol SignInViewModel : class {
}

class VisheoSignInViewModel : SignInViewModel {
    weak var router: SignInRouter?
    
    init() {
    }
}
