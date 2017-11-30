//
//  MenuViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol MenuViewModel : class {
    var username : String {get}
    var userPicture : URL? {get}
    
    var menuItemsCount : Int {get}
    func menuItem(at index: Int) -> MenuItemViewModel
    
    func selectMenu(at index: Int)
}

enum MenuItemType {
    case newVisheo
    case visheoBox
    case premiumCards
    case redeem
    case account
    case contact
}

class VisheoMenuViewModel : MenuViewModel {
    var username: String {
        return userInfo.userName ?? NSLocalizedString("Guest", comment: "Guest user title")
    }
    
    var userPicture: URL? {
        return userInfo.userPicUrl
    }
    
    weak var router: MenuRouter?
    private let userInfo: UserInfoProvider
    private let menuItems : [VisheoMenuItemViewModel]
    
    init(userInfo: UserInfoProvider) {
        self.userInfo = userInfo
        menuItems = [
            VisheoMenuItemViewModel(text: NSLocalizedString("New Visheo", comment: "New visheo menu item"), image: #imageLiteral(resourceName: "newVisheo"), type: .newVisheo),
            VisheoMenuItemViewModel(text: NSLocalizedString("Visheo Box", comment: "Visheo Box menu item"), image: #imageLiteral(resourceName: "visheoBox"), type: .visheoBox),
            VisheoMenuItemViewModel(text: NSLocalizedString("Premium Cards", comment: "Premium Cards menu item"), image: #imageLiteral(resourceName: "premiumCards"), type: .premiumCards),
            VisheoMenuItemViewModel(text: NSLocalizedString("Redeem coupon", comment: "Redeem coupon menu item"), image: #imageLiteral(resourceName: "redeemCoupon"), type: .redeem),
            VisheoMenuItemViewModel(text: NSLocalizedString("My Account", comment: "My Account menu item"), image: #imageLiteral(resourceName: "account"), type: .account),
            VisheoMenuItemViewModel(text: NSLocalizedString("Contact us", comment: "Contact us menu item"), image: #imageLiteral(resourceName: "contactUs"), type: .contact)
        ]
    }
    
    var menuItemsCount: Int {
        return menuItems.count
    }
    
    func selectMenu(at index: Int) {
        switch menuItems[index].type {
        case .newVisheo:
            router?.showCreateVisheo()
        default:
            break;
        }
    }
    
    func menuItem(at index: Int) -> MenuItemViewModel {
        return menuItems[index]
    }
}
