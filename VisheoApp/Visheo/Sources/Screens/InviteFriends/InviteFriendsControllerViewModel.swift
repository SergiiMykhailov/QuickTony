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
    
}

final class InviteFriendsControllerViewModel: InviteFriendsViewModel {
    weak var delegate: InviteFriendsViewModelDelegate?
    
    // MARK: - Private properties -
    private(set) weak var router: InviteFriendsRouter?

    // MARK: - Lifecycle -

    init(router: InviteFriendsRouter) {
        self.router = router
    }

}
