//
//  ChooseCardsViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol ChooseCardsViewModel : class, AlertGenerating, ProgressGenerating, CustomAlertGenerating {
    var smallBundleButtonHidden : Bool {get}
    var bigBundleButtonHidden : Bool {get}

    var smallBundleButtonText : String {get}
    var bigBundleButtonText : String {get}
    
    var premiumCardsNumber : Int {get}
    
    var showBackButton : Bool {get}
    var showFreeSection : Bool {get}
    
    func buySmallBundle()
    func buyBigBundle()
    func sendRegular()
    
    func showMenu()
    func showCoupon()
    
    var didChange : (()->())? {get set}
    var premiumUsageFailedHandler : (()->())? {get set}
    
    func retryPremiumUse()
    
    var confirmFreeSendHandler : (()->())? {get set}
    func sendRegularConfirmed()
}

class VisheoChooseCardsViewModel : ChooseCardsViewModel {
    var confirmFreeSendHandler: (() -> ())?
    var premiumUsageFailedHandler: (() -> ())?
    
    var showBackButton: Bool {
        return !shownFromMenu
    }
    
    var showFreeSection: Bool {
        return premiumCardsNumber == 0
    }
    
    var premiumCardsNumber: Int {
        return purchasesInfo.currentUserPremiumCards
    }
    
    var didChange: (() -> ())? {
        didSet {
            didChange?()
        }
    }
    
    var showProgressCallback: ((Bool) -> ())?
    var successAlertHandler: ((String) -> ())?
    var warningAlertHandler: ((String) -> ())?
    var customAlertHandler: ((String, String) -> ())?
    
    var smallBundleButtonHidden: Bool {
        return purchasesService.smallBundle == nil
    }
    
    var bigBundleButtonHidden: Bool {
        return purchasesService.bigBundle == nil
    }
    
    var smallBundleButtonText: String {
        return description(for: purchasesService.smallBundle) ?? ""
    }
    
    var bigBundleButtonText: String {
        return description(for: purchasesService.bigBundle) ?? ""
    }
    
    private func description(for bundle: PremiumCardsBundle?) -> String? {
        if let description = bundle?.description, let price = bundle?.price, let locale = bundle?.priceLocale {
            let formatter = NumberFormatter()
            formatter.numberStyle = .currency
            formatter.locale = locale
            let priceString = formatter.string(from: price)
            let pricePart = NSString(format: NSLocalizedString(" for %@", comment: "Premium cards price part template") as NSString, priceString ?? "")
            return "\(description)\(pricePart)"
        }
        
        return nil
    }
    
    
    weak var router: ChooseCardsRouter?
    private let purchasesService : PremiumCardsService
    private let purchasesInfo : UserPurchasesInfo
    private let shownFromMenu : Bool
    private let visheoAssets : VisheoRenderingAssets?
    
    init(fromMenu: Bool, purchasesService: PremiumCardsService, purchasesInfo: UserPurchasesInfo, assets: VisheoRenderingAssets?) {
        self.purchasesService = purchasesService
        self.purchasesInfo = purchasesInfo
        self.shownFromMenu = fromMenu
        self.visheoAssets = assets
        
        if purchasesService.smallBundle == nil || purchasesService.bigBundle == nil {
            purchasesService.reloadPurchases()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.loadingPremiumBundlesFailed, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.warningAlertHandler?(NSLocalizedString("Failed to load purchases info", comment: "Failed to load purchases from iTunes store message text"))
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.bundlePurchaseFailed, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.showProgressCallback?(false)
            self?.warningAlertHandler?(NSLocalizedString("Failed to purchase cards bundle", comment: "Failed to purchase bundle"))
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.bundlePurchaseDeferred, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.showProgressCallback?(false)
            self?.customAlertHandler?(NSLocalizedString("Waiting For Approval", comment: "Waiting For Approval alert title"),
                NSLocalizedString("Thank you! You can continue to use Visheo while your purchase is pending an approval from your parent.", comment: "Purcahse pending due to parental control alert text"))
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.premiumBundlesLoaded, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.didChange?()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoChooseCardsViewModel.purchaseSucceded), name: Notification.Name.bundlePurchaseSucceded, object: nil)
                
        NotificationCenter.default.addObserver(forName: Notification.Name.bundlePurchaseCancelled, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.showProgressCallback?(false)
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoChooseCardsViewModel.updatePremCardsNumber), name: Notification.Name.userPremiumCardsCountChanged, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func sendRegular() {
        if visheoAssets != nil {
            confirmFreeSendHandler?()
        } else {
            router?.showCreateVisheo()
        }
    }
    
    func sendRegularConfirmed() {
        if let assets = visheoAssets {
            router?.showShareVisheo(with: assets, premium: false)
        } else {
            router?.showCreateVisheo()
        }

    }
    
    func buyBigBundle() {
        if let bundle = purchasesService.bigBundle {
            showProgressCallback?(true)
            purchasesService.buy(bundle: bundle)
        }
    }
    
    func buySmallBundle() {
        if let bundle = purchasesService.smallBundle {
            showProgressCallback?(true)
            purchasesService.buy(bundle: bundle)
        }
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    func showCoupon() {
        router?.showCoupon(with: visheoAssets)
    }
    
    func retryPremiumUse() {
        usePremCard()
    }
    
    private func usePremCard() {
        if let assets = visheoAssets {
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
    
    // MARK: Notifications
    
    @objc func updatePremCardsNumber() {
        self.didChange?()
    }
    
    @objc func purchaseSucceded() {
        self.showProgressCallback?(false)
        usePremCard()
    }
}
