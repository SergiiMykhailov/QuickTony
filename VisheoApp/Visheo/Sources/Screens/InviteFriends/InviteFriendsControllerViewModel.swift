//
//  InviteFriendsControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/10/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol InviteFriendsViewModelDelegate: class {
    func refreshUI()
}

protocol InviteFriendsViewModel: class {
    var inviteUrl : URL? {get}
    var inviteLink : String? {get}
    
    func showMenu()
    
    func trackLinkCopied()
    func trackLinkShared()
    func trackFacebookShared()
    func trackTwitterShared()
}

final class InviteFriendsControllerViewModel: InviteFriendsViewModel {
    weak var delegate: InviteFriendsViewModelDelegate?
    
    var inviteUrl: URL? {
        return URL.init(string: self.inviteLink ?? "")
    }
    var inviteLink: String? {
        return "https://visheo.com/invite/UoiAdIH4"
    }
    
    // MARK: - Private properties -
    private(set) weak var router: InviteFriendsRouter?
    private let loggingService: EventLoggingService

    // MARK: - Lifecycle -

    init(router: InviteFriendsRouter, loggingService: EventLoggingService) {
        self.router = router
        self.loggingService = loggingService
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    func trackLinkCopied() {
        loggingService.log(event: InviteURLCopiedEvent())
    }
    
    func trackLinkShared() {
        loggingService.log(event: InviteURLSharedEvent())
    }
    
    func trackFacebookShared() {
        loggingService.log(event: InviteFacebookSharedEvent())
    }
    
    func trackTwitterShared() {
        loggingService.log(event: InviteTwitterSharedEvent())
    }
}
