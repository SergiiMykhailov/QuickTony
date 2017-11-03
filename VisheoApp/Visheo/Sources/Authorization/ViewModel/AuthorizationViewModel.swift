//
//  AuthorizationViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol AuthorizationViewModel : class {
    func loginWithGoogle()
    func loginWithFacebook()
    
    var showProgressCallback : ((Bool) -> ())? {get set}
    var getPresentationViewController : (() -> (UIViewController?))? {get set}
    var warningAlertHandler : ((String) -> ())? {get set}
}

class VisheoAutorizationViewModel : AuthorizationViewModel {
    var warningAlertHandler: ((String) -> ())?
    var getPresentationViewController: (() -> (UIViewController?))?
    var showProgressCallback: ((Bool) -> ())?
    
    weak var router: AuthorizationRouter?
    var authService : AuthorizationService
    
    init(authService: AuthorizationService) {
        self.authService = authService
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoAutorizationViewModel.processLogin), name: .userLoggedIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoAutorizationViewModel.processLoginFail(notification:)), name: .userLoginFailed, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loginWithGoogle() {
        self.showProgressCallback?(true)
        self.authService.loginWithGoogle(from: getPresentationViewController?())
    }
    
    func loginWithFacebook() {
        self.showProgressCallback?(true)
        self.authService.loginWithFacebook(from: getPresentationViewController?())
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
