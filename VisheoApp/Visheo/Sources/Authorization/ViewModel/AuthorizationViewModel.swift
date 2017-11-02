//
//  AuthorizationViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol AuthorizationViewModel : class {
}

class VisheoAutorizationViewModel : AuthorizationViewModel {
    weak var router: AuthorizationRouter?
    
    init() {
    }
}
