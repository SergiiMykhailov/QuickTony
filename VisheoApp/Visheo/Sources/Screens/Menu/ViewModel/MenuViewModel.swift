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
	private let notificationService: UserNotificationsService;
	private let visheoListService: VisheosListService;
    private let menuItems : [VisheoMenuItemViewModel]
	private var pendingVisheoIds = Set<String>()
    
    init(userInfo: UserInfoProvider, notificationService: UserNotificationsService, visheoListService: VisheosListService) {
        self.userInfo = userInfo
		self.notificationService = notificationService;
		self.visheoListService = visheoListService;
        menuItems = [
            VisheoMenuItemViewModel(text: NSLocalizedString("New Visheo", comment: "New visheo menu item"), image: #imageLiteral(resourceName: "newVisheo"), type: .newVisheo),
            VisheoMenuItemViewModel(text: NSLocalizedString("Visheo Box", comment: "Visheo Box menu item"), image: #imageLiteral(resourceName: "visheoBox"), type: .visheoBox),
            VisheoMenuItemViewModel(text: NSLocalizedString("Premium Cards", comment: "Premium Cards menu item"), image: #imageLiteral(resourceName: "premiumCards"), type: .premiumCards),
            VisheoMenuItemViewModel(text: NSLocalizedString("Redeem coupon", comment: "Redeem coupon menu item"), image: #imageLiteral(resourceName: "redeemCoupon"), type: .redeem),
            VisheoMenuItemViewModel(text: NSLocalizedString("My Account", comment: "My Account menu item"), image: #imageLiteral(resourceName: "account"), type: .account),
            VisheoMenuItemViewModel(text: NSLocalizedString("Contact us", comment: "Contact us menu item"), image: #imageLiteral(resourceName: "contactUs"), type: .contact)
        ]
		
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoMenuViewModel.handleVisheoOpen(_:)), name: .openVisheoFromReminder, object: nil);
		
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoMenuViewModel.handleVisheosListChange(_:)), name: .visheosChanged, object: nil);
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self);
	}
    
    var menuItemsCount: Int {
        return menuItems.count
    }
    
    func selectMenu(at index: Int) {
        switch menuItems[index].type {
        case .newVisheo:
            router?.showCreateVisheo()
        case .visheoBox:
            router?.showVisheoBox()
        case .account:
            router?.showAccount()
        case .premiumCards:
            if userInfo.isAnonymous {
                router?.showRegistration()
            } else {
                router?.showPremiumCards()
            }
        default:
            break;
        }
    }
    
    func menuItem(at index: Int) -> MenuItemViewModel {
        return menuItems[index]
    }
	
	@objc private func handleVisheoOpen(_ notification: Notification) {
		guard let visheoId = notification.userInfo?[UserNotificationsServiceNotificationKeys.id] as? String else {
			return;
		}
		
		if let record = visheoListService.visheosRecords.filter({ $0.id == visheoId }).first {
			router?.showVisheoScreen(with: record);
		} else {
			pendingVisheoIds.insert(visheoId);
		}
	}
	
	@objc private func handleVisheosListChange(_ notification: Notification)
	{
		var handledRecords: [String] = []
		for visheoId in pendingVisheoIds {
			if let record = visheoListService.visheosRecords.filter({ $0.id == visheoId }).first, let _ = record.visheoLink {
				router?.showVisheoScreen(with: record);
				handledRecords.append(visheoId)
			}
		}
		handledRecords.forEach{
			pendingVisheoIds.remove($0);
		}
	}
}
