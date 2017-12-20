//
//  RedeemViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol RedeemViewModel : class, ProgressGenerating, WarningAlertGenerating {
    func showMenu()
    func redeem(coupon: String)
    
    var showBackButton: Bool {get}
}

class VisheoRedeemViewModel : RedeemViewModel {
    var showBackButton: Bool
    var showProgressCallback: ((Bool) -> ())?
    var warningAlertHandler: ((String) -> ())?
    
    weak var router: RedeemRouter?
    private let purchasesService: PremiumCardsService
	private let appStateService: AppStateService
	private let loggingService: EventLoggingService
    private let assets : VisheoRenderingAssets?
     
	init(purchasesService: PremiumCardsService, appStateService: AppStateService, loggingService: EventLoggingService, showBack: Bool, assets : VisheoRenderingAssets? = nil) {
        self.purchasesService = purchasesService
		self.appStateService = appStateService;
		self.loggingService = loggingService;
        self.assets = assets
        showBackButton = showBack
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    func redeem(coupon: String) {
		guard !coupon.isEmpty else {
			warningAlertHandler?(NSLocalizedString("Enter coupon code", comment: "Missing coupon code"));
			return;
		}
		
		guard appStateService.isReachable else {
			warningAlertHandler?(NSLocalizedString("You seem to have lost Internet connection", comment: "No internet connection"));
			return;
		}
		
        showProgressCallback?(true)
        purchasesService.redeem(coupon: coupon) { [weak self] (count, error) in
			guard let `self` = self else { return }
            self.showProgressCallback?(false)
            if let error = error {
                self.warningAlertHandler?(self.errorString(from: error))
            } else {
				self.loggingService.log(event: CouponRedeemedEvent())
				self.router?.showSuccess(with: count ?? 0, assets: self.assets);
            }
        }
    }
    
    private func errorString(from error: RedeemError) -> String {
        switch error {
        case .unknown:
            return NSLocalizedString("Oops… Something went wrong.", comment: "Unknown error redeeming coupon")
        case .invalidCoupon:
            return NSLocalizedString("Coupon with this code does not exist. Please check if you entered the code right.", comment: "Invalid coupon code error")
        case .expired:
            return NSLocalizedString("This coupon has expired.", comment: "Coupon expired error")
        case .exceededLimit:
            return NSLocalizedString("This coupon has reached maximum number of allowed redeems.", comment: "Coupon limit exceeeded")
        case .alreadyRedeemed:
            return NSLocalizedString("This coupon has been redeemed already.", comment: "Coupon already redeemed error")
        }
    }
}
