//
//  RedeemSuccessViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


enum RedeemSuccessType {
	case couponRedeem
	case inAppPurchase
}


protocol RedeemSuccessViewModel : class, AlertGenerating, CustomAlertGenerating, ProgressGenerating {
    var redeemedDescription: String {get}
    
    func showMenu()
    func createOrContinue()
	
	var premiumUsageFailedHandler : (()->())? {get set}
	func retryPremiumUse()
	
	var showBackButton: Bool { get }
	var continueDescription: String { get }
	var titleDescription: String { get }
}

class VisheoRedeemSuccessViewModel : RedeemSuccessViewModel {
	var showProgressCallback: ((Bool) -> ())?
	var premiumUsageFailedHandler: (() -> ())?
	var customAlertHandler: ((String, String) -> ())?
	var successAlertHandler: ((String) -> ())?
	var warningAlertHandler: ((String) -> ())?
	
    weak var router: RedeemSuccessRouter?
    private let redeemedCount : Int
	private let assets: VisheoRenderingAssets?;
	private let purchasesService: PremiumCardsService;
	private let type: RedeemSuccessType;
	private (set) var showBackButton: Bool;
	
	init(with type: RedeemSuccessType, count: Int, assets: VisheoRenderingAssets? = nil, purchasesService: PremiumCardsService, showBackButton: Bool) {
        redeemedCount = count
		self.assets = assets;
		self.purchasesService = purchasesService;
		self.showBackButton = showBackButton;
		self.type = type;
    }
    
    var redeemedDescription: String {
        if (purchasesService.currentUserSubscriptionState() == .active)
        {
            return String(format: NSLocalizedString("You successfully purchased subscription", comment: "redeem success description"))
        }
        
        return String(format: NSLocalizedString("%d premium card(s) added to your account", comment: "redeem success description"), redeemedCount)
    }
	
	var continueDescription: String {
		if let _ = assets {
			return NSLocalizedString("Send your Visheo", comment: "Send your Visheo");
		} else {
			return NSLocalizedString("Create Visheo Card", comment: "Create Visheo Card");
		}
	}
	
	var titleDescription: String {
		switch type {
			case .couponRedeem:
				return NSLocalizedString("Enter coupon code", comment: "Enter coupon code");
			case .inAppPurchase:
				return NSLocalizedString("Purchase succeeded", comment: "Purchase succeeded");
		}
	}
    
    func showMenu() {
        router?.showMenu()
    }
    
    func createOrContinue() {
		if let _ = assets {
			makePremiumContent();
		} else {
			router?.showCreate();
		}
    }
	
    func makePremiumContent() {
        if (purchasesService.currentUserSubscriptionState() != .none) {
            useSubscription()
            return
        }
        usePremCard()
    }
    
	func retryPremiumUse() {
		makePremiumContent()
	}
	
    private func useSubscription() {
        guard let assets = assets else { return }
        if (purchasesService.currentUserSubscriptionState() == .active) {
            self.router?.showShareVisheo(with: assets, premium: true)
        } else if purchasesService.currentUserSubscriptionState() == .expired {
            showProgressCallback?(true)
            purchasesService.checkSubscriptionStateRemotely() { [unowned self] purchaseResult, error in
                self.showProgressCallback?(false)
                if let purchaseResult = purchaseResult {
                    switch purchaseResult {
                        case .purchased(_,_):
                            self.router?.showShareVisheo(with: assets, premium: true)
                        case .expired(_,_):
                            self.router?.showCreate();
                        case .notPurchased:
                            self.router?.showCreate();
                    }
                } else if error != nil {
                    self.router?.showCreate();
                }
            }
        }
    }
    
	private func usePremCard() {
		guard let `assets` = assets else {
			return;
		}
		showProgressCallback?(true)
		purchasesService.usePremiumCard(completion: { (success) in
			self.showProgressCallback?(false)
			if success {
				self.router?.showShareVisheo(with: assets, premium: true)
			} else {
				self.premiumUsageFailedHandler?()
			}
		})
	}
}
