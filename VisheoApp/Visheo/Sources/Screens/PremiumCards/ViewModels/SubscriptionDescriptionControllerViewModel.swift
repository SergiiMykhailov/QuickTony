//
//  SubscriptionDescriptionControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/18/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol SubscriptionDescriptionViewModelDelegate: class {
    func refreshUI()
}

protocol SubscriptionDescriptionViewModel: class, AlertGenerating, ProgressGenerating, CustomAlertGenerating {
    weak var delegate: SubscriptionDescriptionViewModelDelegate? {get}
    var subscribptionDescription : String? {get}
    func paySubscription()
}


final class SubscriptionDescriptionControllerViewModel: SubscriptionDescriptionViewModel  {

    weak var delegate: SubscriptionDescriptionViewModelDelegate?
    
    var subscribptionDescription : String? {
        if let price = purchasesService.subscription?.price,
            let locale = purchasesService.subscription?.priceLocale,
            let iosDescription = purchasesService.subscription?.iosDescription {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            let priceString = formatter.string(from: price)
            return String(format:iosDescription, priceString ?? "")
        }
        return nil
    }
    
    var showProgressCallback: ((Bool) -> ())?
    var successAlertHandler: ((String) -> ())?
    var warningAlertHandler: ((String) -> ())?
    var customAlertHandler: ((String, String) -> ())?
    
    let purchasesService: PremiumCardsService
    
    // MARK: - Private properties -
    private(set) weak var router: SubscriptionDescriptionRouter?

    // MARK: - Lifecycle -

    init(router: SubscriptionDescriptionRouter, delegate: SubscriptionDescriptionViewModelDelegate?, purchasesService: PremiumCardsService) {
        self.router = router
        self.purchasesService = purchasesService
        self.delegate = delegate
        
        NotificationCenter.default.addObserver(forName: Notification.Name.bundlePurchaseFailed, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.showProgressCallback?(false)
            self?.warningAlertHandler?(NSLocalizedString("Failed to purchase cards bundle", comment: "Failed to purchase bundle"))
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.bundlePurchaseDeferred, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.showProgressCallback?(false)
            self?.customAlertHandler?(NSLocalizedString("Waiting For Approval", comment: "Waiting For Approval alert title"),
                                      NSLocalizedString("Thank you! You can continue to use Visheo while your purchase is pending an approval from your parent.", comment: "Purcahse pending due to parental control alert text"))
        }
        NotificationCenter.default.addObserver(forName: Notification.Name.bundlePurchaseCancelled, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.showProgressCallback?(false)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.userSubscriptionStateChanged, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            self?.delegate?.refreshUI()
        }
    }

    
    func paySubscription() {
        if let product = purchasesService.subscription {
            self.showProgressCallback?(true)
            purchasesService.buy(bundle: product)
        }
    }
    
    
    // MARK: Notifications
    
    @objc func purchaseSucceeded(_ notification: Notification) {
        self.showProgressCallback?(false)
        router?.showPurchaseSuccess()
    }
}
