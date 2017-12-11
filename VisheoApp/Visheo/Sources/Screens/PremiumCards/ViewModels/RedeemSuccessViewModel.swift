//
//  RedeemSuccessViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol RedeemSuccessViewModel : class {
    var redeemedDescription: String {get}
    
    func showMenu()
    func showCreate()
}

class VisheoRedeemSuccessViewModel : RedeemSuccessViewModel {
    weak var router: RedeemSuccessRouter?
    private let redeemedCount : Int
    init(with count: Int) {
        redeemedCount = count
    }
    
    var redeemedDescription: String {
        return String(format: NSLocalizedString("%d premium card(s) added to your account", comment: "redeem success description"), redeemedCount)
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    func showCreate() {
        router?.showCreate()
    }
}
