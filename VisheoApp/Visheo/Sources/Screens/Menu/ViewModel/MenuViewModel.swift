//
//  MenuViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol MenuViewModel : class, SuccessAlertGenerating, WarningAlertGenerating {
    var username : String {get}
    var userPicture : URL? {get}
    
    var menuItemsCount : Int {get}
    func menuItem(at index: Int) -> MenuItemViewModel
    
    var didChange : (()->())? {get set}
    
    func selectMenu(at index: Int)
	func showAccount()
}

enum MenuItemType {
    case newVisheo
    case visheoBox
    case premiumCards
    case inviteFriends
    case redeem
    case bestPracticies
    case contact
}

class VisheoMenuViewModel : MenuViewModel {
	var successAlertHandler: ((String) -> ())?
	var warningAlertHandler: ((String) -> ())?
	
    var username: String {
        return userInfo.userName ?? NSLocalizedString("Guest", comment: "Guest user title")
    }
    
    var userPicture: URL? {
        return userInfo.userPicUrl
    }
    
    var didChange : (() -> ())?
    
    weak var router: MenuRouter?
    private let userInfo: UserInfoProvider
	private let notificationService: UserNotificationsService
	private let visheoListService: VisheosListService
    private let appStateService: AppStateService
    private let loggingService: EventLoggingService
    
    private var menuItems : [VisheoMenuItemViewModel] {
        get {
            let couponButton = VisheoMenuItemViewModel(text: NSLocalizedString("Redeem coupon", comment: "Redeem coupon menu item"), image: #imageLiteral(resourceName: "redeemCoupon"), subText: nil, type: .redeem)
            let inviteButton = VisheoMenuItemViewModel(text: NSLocalizedString("Invite friends", comment: "Invite frinds menu item"), image: #imageLiteral(resourceName: "inviteFriends"), subText: NSLocalizedString("& get Visheo Cards for FREE", comment: "Invite friends menu substring"), type: .inviteFriends)
            
            let menuItems = [
                VisheoMenuItemViewModel(text: NSLocalizedString("New Visheo", comment: "New visheo menu item"), image: #imageLiteral(resourceName: "newVisheo"), subText: nil, type: .newVisheo),
                VisheoMenuItemViewModel(text: NSLocalizedString("Visheo Box", comment: "Visheo Box menu item"), image: #imageLiteral(resourceName: "visheoBox"), subText: nil, type: .visheoBox),
                VisheoMenuItemViewModel(text: NSLocalizedString("My Purchases", comment: "My purchases menu item"), image: #imageLiteral(resourceName: "premiumCards"), subText: nil, type: .premiumCards),
                appStateService.isInviteFriendsAvailable ? inviteButton : nil,
                VisheoMenuItemViewModel(text: NSLocalizedString("Best Practicies", comment: "Best Practicies menu item"), image: #imageLiteral(resourceName: "bestPracticies"), subText: nil, type: .bestPracticies),
                appStateService.isCouponAvailable ? couponButton : nil,
                VisheoMenuItemViewModel(text: NSLocalizedString("Contact us", comment: "Contact us menu item"), image: #imageLiteral(resourceName: "contactUs"), subText: nil, type: .contact)
                ].flatMap{$0}
            
            return menuItems
        }
    }
	private var pendingVisheoIds = Set<String>()
    
    init(userInfo: UserInfoProvider,
         notificationService: UserNotificationsService,
         visheoListService: VisheosListService,
         appStateService: AppStateService,
         loggingService: EventLoggingService) {
        self.userInfo = userInfo
		self.notificationService = notificationService
		self.visheoListService = visheoListService
		self.appStateService = appStateService
        self.loggingService = loggingService

		NotificationCenter.default.addObserver(self, selector: #selector(VisheoMenuViewModel.handleVisheoOpen(_:)), name: .openVisheoFromReminder, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoMenuViewModel.handleVisheosListChange(_:)), name: .visheosChanged, object: nil)
		
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoMenuViewModel.feedbackSent), name: .contactUsFeedbackSent, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoMenuViewModel.failedToSendFeedback(_:)), name: .contactUsFeedbackFailed, object: nil)
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.couponAvailableChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.didChange?()
        }
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.inviteFriendsAvailableChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.didChange?()
        }
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self)
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
        case .inviteFriends:
            if userInfo.isAnonymous {
                router?.showRegistration(with: .inviteFriends);
            } else {
                router?.showInvites()
            }
        case .bestPracticies:
            loggingService.log(event: BestPracticesClicked())
            router?.showBestPracticies()
        case .premiumCards:
            if userInfo.isAnonymous {
				router?.showRegistration(with: .premiumCards)
            } else {
                router?.showPremiumCards()
            }
        case .redeem:
			if userInfo.isAnonymous {
				router?.showRegistration(with: .redeemCoupons)
			} else {
				router?.showCoupons()
			}
		case .contact:
			if userInfo.isAnonymous {
				router?.showRegistration(with: .sendFeedback)
			} else {
				router?.showContactForm()
			}
        }
    }
    
    func menuItem(at index: Int) -> MenuItemViewModel {
        return menuItems[index]
    }
	
	func showAccount() {
		router?.showAccount()
	}
	
	@objc private func handleVisheoOpen(_ notification: Notification) {
		guard let visheoId = notification.userInfo?[UserNotificationsServiceNotificationKeys.id] as? String else {
			return
		}
		
		if let record = visheoListService.visheosRecords.filter({ $0.id == visheoId }).first {
			router?.showVisheoScreen(with: record)
		} else {
			pendingVisheoIds.insert(visheoId)
		}
	}
	
	@objc private func handleVisheosListChange(_ notification: Notification)
	{
		var handledRecords: [String] = []
		for visheoId in pendingVisheoIds {
			if let record = visheoListService.visheosRecords.filter({ $0.id == visheoId }).first, let _ = record.visheoLink {
				router?.showVisheoScreen(with: record)
				handledRecords.append(visheoId)
			}
		}
		handledRecords.forEach{
			pendingVisheoIds.remove($0)
		}
	}
	
	@objc func feedbackSent() {
		let message = NSLocalizedString("Your message has been sent. Thanks for contacting us!", comment: "Contact us feedback sent")
		successAlertHandler?(message)
	}
	
	@objc func failedToSendFeedback(_ notification: Notification) {
		guard let userInfo = notification.userInfo as? [ FeedbackServiceNotificationKeys : Any ],
			let error = userInfo[.error] as? FeedbackServiceError else {
			return
		}
		var message: String
		switch error {
			case .setupMailClient:
				message = NSLocalizedString("Please setup your email client to send feedback", comment: "Email client not setup error message")
			case .underlying,
				 .generic:
				message = NSLocalizedString("Oops… Something went wrong.", comment: "Unknown error sending feedback")
		}
		warningAlertHandler?(message)
	}
}
