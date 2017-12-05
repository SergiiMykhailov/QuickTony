//
//  AccountViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol AccountViewModel : class {
    var avatarUrl : URL? {get}
    var userName : String {get}
    
    var allowEdit : Bool {get}
    
    func showMenu()
    func editAccount()
}

class VisheoAccountViewModel : AccountViewModel {
    var allowEdit: Bool {
        return !authService.isAnonymous
    }
    
    var avatarUrl: URL? {
        return userInfo.userPicUrl
    }
    
    var userName: String {
        return userInfo.userName ?? NSLocalizedString("Guest", comment: "Guest user title")
    }
    
    weak var router: AccountRouter?
    private let userInfo : UserInfoProvider
    private let authService : AuthorizationService
    
    init(userInfo: UserInfoProvider, authService: AuthorizationService) {
        self.userInfo = userInfo
        self.authService = authService
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    func editAccount() {
        router?.showEdit(userName: userName)
    }
}
