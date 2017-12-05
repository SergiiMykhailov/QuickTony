//
//  EditAccountViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol EditAccountViewModel : class, ProgressGenerating, RequiredFieldAlertGenerating, AlertGenerating {
    func saveEditing()
    func deleteAccount()
    func reloginConfirmed()
    
    var userName: String {get set}
    var reloginConfirmationHandler: (()->())? {get set}
}

class VisheoEditAccountViewModel : EditAccountViewModel {
    var reloginConfirmationHandler: (() -> ())?
    
    var userName: String
    var showProgressCallback: ((Bool) -> ())?
    var requiredFieldAlertHandler: ((String) -> ())?
    var successAlertHandler: ((String) -> ())?
    var warningAlertHandler: ((String) -> ())?
    
    weak var router: EditAccountRouter?
    private let authService : AuthorizationService
    
    init(userName: String, authService: AuthorizationService) {
        self.authService = authService
        self.userName = userName
    }
    
    func saveEditing() {
        if userName.isEmpty {
            requiredFieldAlertHandler?(NSLocalizedString("Please enter your name", comment: "Required name"))
        } else {
            showProgressCallback?(true)
            authService.set(username: userName, completion: { (success) in
                self.showProgressCallback?(false)
                if success {
                    self.successAlertHandler?(NSLocalizedString("User name changed successfully", comment: "USername change success"))
                } else {
                    self.warningAlertHandler?(NSLocalizedString("An error occurred while renaming", comment: "Error while deleting account text messaage"))
                }
            })
        }
    }
    
    func deleteAccount() {
        showProgressCallback?(true)
        authService.deleteAccount { (error) in
            self.showProgressCallback?(false)
            switch (error) {
            case .some(.needSignIn):
                self.reloginConfirmationHandler?()
            case .some(_):
                self.warningAlertHandler?(NSLocalizedString("An error occurred while deleting account", comment: "Error while deleting account text messaage"))
            case .none:
                self.router?.showRegistration()
            }
        }
    }
    
    func reloginConfirmed() {
        authService.signOut { (success) in
            if success {
                self.router?.showRegistration()
            } else {
                self.warningAlertHandler?(NSLocalizedString("An error occurred while signing out", comment: "Error while sign out text messaage"))
            }
        }
    }
}
