//
// Created by Petro Kolesnikov on 12/6/17.
// Copyright (c) 2017 Olearis. All rights reserved.
//

import Foundation
import StoreKit
import Firebase

extension Notification.Name {
    static let premiumBundlesLoaded = Notification.Name("premiumBundlesLoaded")
    static let loadingPremiumBundlesFailed = Notification.Name("loadingPremiumBundlesFailed")
    
    static let bundlePurchaseFailed = Notification.Name("bundlePurchaseFailed")
    static let bundlePurchaseCancelled = Notification.Name("bundlePurchaseCancelled")
    static let bundlePurchaseSucceded = Notification.Name("bundlePurchaseSucceded")
    static let bundlePurchaseDeferred = Notification.Name("bundlePurchaseDeferred")
    
    static let userPremiumCardsCountChanged = Notification.Name("userPremiumCardsCountChanged")
}

enum RedeemError : Error {
    case unknown
    case invalidCoupon
    case expired
    case exceededLimit
    case alreadyRedeemed
}

protocol UserPurchasesInfo {
    var currentUserPremiumCards : Int {get}
}

protocol PremiumCardsService {
    func reloadPurchases()
    var smallBundle : PremiumCardsBundle? {get}
    var bigBundle : PremiumCardsBundle? {get}
    
    func buy(bundle: PremiumCardsBundle)
    func redeem(coupon: String, completion: @escaping (Int?, RedeemError?)->())
    
    func usePremiumCard(completion: @escaping (Bool)->())
}


class PremiumCardsBundle {
    var price : NSDecimalNumber? {
        return skProduct?.price
    }
    
    var priceLocale : Locale? {
        return skProduct?.priceLocale
    }
    
    var description : String? {
        return skProduct?.localizedDescription
    }
    
    fileprivate let cardsCount : Int
    fileprivate let productId : String
    fileprivate var skProduct : SKProduct?
    
    fileprivate init?(snapshot: DataSnapshot?) {
        guard let snapshot = snapshot,
            let cardsCount = snapshot.childSnapshot(forPath: "cardsCount").value as? Int,
            let productId = snapshot.childSnapshot(forPath:"appleId").value as? String else {return nil}
        
        self.cardsCount = cardsCount
        self.productId = productId
    }
    
    fileprivate func update(with product: SKProduct) {
        skProduct = product
    }
}

class VisheoPremiumCardsService : NSObject, PremiumCardsService, UserPurchasesInfo, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    enum Constants {
        static let smallBundleId = "smallCardsPack"
        static let bigBundleId = "bigCardsPack"
    }
    
    var smallBundle: PremiumCardsBundle?
    var bigBundle: PremiumCardsBundle?
    var currentUserPremiumCards: Int {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.userPremiumCardsCountChanged, object: self)
        }
    }
    
    private var productsRequest : SKProductsRequest?
    private let userInfoProvider : UserInfoProvider
    
    private var premCardsReference : DatabaseReference?
    
    init(userInfoProvider: UserInfoProvider) {
        self.userInfoProvider = userInfoProvider
        currentUserPremiumCards = 0
        super.init()
        loadPurchases()
        startPremiumCardsObserving()
        SKPaymentQueue.default().add(self)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.authStateChanged, object: nil, queue: OperationQueue.main) { (notification) in
            self.currentUserPremiumCards = 0
            self.startPremiumCardsObserving()
        }
    }
    
    private func startPremiumCardsObserving() {
        if let oldReference = premCardsReference {
            oldReference.removeAllObservers()
        }
        
        if let userId = userInfoProvider.userId {
            let userPremCardsRef = Database.database().reference(withPath: "users/\(userId)/purchases/premiumCards")
            premCardsReference = userPremCardsRef
            
            userPremCardsRef.observe(.value, with: { (snapshot) in
                self.currentUserPremiumCards = snapshot.value as? Int ?? 0
            })
        }
    }
    
    func reloadPurchases() {
        loadPurchases()
    }
    
    func buy(bundle: PremiumCardsBundle) {
        if let product = bundle.skProduct {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        }
    }
    
    func usePremiumCard(completion: @escaping (Bool)->()) {
        guard let userId = userInfoProvider.userId else {
            completion(false)
            return
        }
        
        spendCard(for: userId, completion: completion)
    }
    
    func redeem(coupon couponCode: String, completion: @escaping (Int?, RedeemError?)->()) {
        guard let userId = userInfoProvider.userId else {
            completion(nil, .unknown)
            return
        }
        
        let couponId = couponCode.uppercased()
        var cardsToAdd = 0
        var redeemError : RedeemError? = nil
        
        Database.database().reference(withPath: "coupons/\(couponId)/").keepSynced(true)
        
        Database.database().reference(withPath: "coupons/\(couponId)/").observeSingleEvent(of: .value) { (_) in
            Database.database().reference(withPath: "coupons/\(couponId)/").runTransactionBlock({ (currentData) -> TransactionResult in
                if var coupon = currentData.value as? [String : Any] {
                    cardsToAdd = coupon["cards_amount"] as? Int ?? 0
                    
                    if !self.validate(date: coupon["expires"] as? String) {
                        redeemError = .expired
                        var lateRedeems = coupon["late_redeems"] as? [String: Any] ?? [String: Any]()
                        lateRedeems[userId] = true
                        coupon["late_redeems"] = lateRedeems
                        currentData.value = coupon
                        return TransactionResult.success(withValue: currentData)
                    }
                    
                    var redeemed = coupon["redeemed"] as? [String: Any] ?? [String: Any]()
                    
                    if redeemed[userId] != nil {
                        redeemError = .alreadyRedeemed
                        return TransactionResult.abort()
                    }
                    
                    if let maxUsers = coupon["max_users"] as? Int, redeemed.count >= maxUsers {
                        redeemError = .exceededLimit
                        return TransactionResult.abort()
                    }
                    redeemed[userId] = true
                    coupon["redeemed"] = redeemed
                    currentData.value = coupon
                    return TransactionResult.success(withValue: currentData)
                } else {
                    redeemError = .invalidCoupon
                    return TransactionResult.abort()
                }
            }, andCompletionBlock: { (error, commited, snapshot) in
                if let redeemError = redeemError {
                    completion(nil, redeemError)
                } else if error != nil {
                    completion(nil, .unknown)
                } else {
                    self.processBuying(cards: cardsToAdd, for: userId, completion: { (success) in
                        if success {
                            completion(cardsToAdd, nil)
                        } else {
                            completion(nil, .unknown)
                        }                        
                    })
                }
            } , withLocalEvents: false)
        }
    }
    
    // MARK: Private
    
    private func validate(date string: String?) -> Bool {
        guard let dateString = string else { return false }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = .withFullDate
        
        guard let date = formatter.date(from: dateString) else { return false }
        
        return date.daysFromNow >= 0
    }
    
    private func loadPurchases() {
        Database.database().reference(withPath: "availablePurchases").observe(.value) { (snapshot) in
            self.smallBundle = PremiumCardsBundle(snapshot: snapshot.childSnapshot(forPath: Constants.smallBundleId))
            self.bigBundle   = PremiumCardsBundle(snapshot: snapshot.childSnapshot(forPath: Constants.bigBundleId))
            
            var products = Set<String>()
            if let smallId = self.smallBundle?.productId {products.insert(smallId)}
            if let bigId = self.bigBundle?.productId {products.insert(bigId)}
            self.startProductrequest(for: products)
        }
    }
    
    private func startProductrequest(for products: Set<String>) {
        productsRequest = SKProductsRequest(productIdentifiers: products)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    private func bundle(for productId: String) -> PremiumCardsBundle? {
        if productId == self.bigBundle?.productId {
            return self.bigBundle
        }
        if productId == self.smallBundle?.productId {
            return self.smallBundle
        }
        return nil
    }
    
    private func spendCard(for user: String, completion: @escaping (Bool)->()) {        
        Database.database().reference(withPath: "users/\(user)/purchases").keepSynced(true)
        Database.database().reference(withPath: "users/\(user)/purchases").observeSingleEvent(of: .value) { (snapshot) in
            Database.database().reference(withPath: "users/\(user)/purchases").runTransactionBlock({ (currentData) -> TransactionResult in
                if var purchases = currentData.value as? [String : Any] {
                    var premCards = purchases["premiumCards"] as? Int ?? 0
                    if premCards <= 0 {
                        return TransactionResult.abort()
                    } else {
                        premCards -= 1
                        purchases["premiumCards"] = premCards
                        currentData.value = purchases
                        return TransactionResult.success(withValue: currentData)
                    }
                } else {
                    return TransactionResult.abort()
                }
            }, andCompletionBlock: { (error, commited, snapshot) in
                completion(commited)
            }, withLocalEvents: false)
        }
    }
    
    // MARK: Products request delegate
    
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        response.products.forEach {
            bundle(for: $0.productIdentifier)?.update(with: $0)
        }
        NotificationCenter.default.post(name: Notification.Name.premiumBundlesLoaded, object: self)
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        NotificationCenter.default.post(name: Notification.Name.loadingPremiumBundlesFailed, object: self)
    }
    
    // MARK: Payment queue observer
    
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        queue.transactions.forEach {
            switch $0.transactionState {
            case .failed:
                fail(transaction: $0)
            case .purchasing:
                break
            case .purchased:
                succeded(transaction: $0)
            case .restored:
                restored(transaction: $0)
            case .deferred:
                deferred(transaction: $0)
            }
        }
    }
    
    private func fail(transaction: SKPaymentTransaction) {
        if let transactionError = transaction.error as NSError?,
                transactionError.code == SKError.paymentCancelled.rawValue {
            NotificationCenter.default.post(name: Notification.Name.bundlePurchaseCancelled, object: self)
        } else {
            NotificationCenter.default.post(name: Notification.Name.bundlePurchaseFailed, object: self)
        }
        
        SKPaymentQueue.default().finishTransaction(transaction)
    }
    
    private func succeded(transaction: SKPaymentTransaction) {
        guard let bundle = bundle(for: transaction.payment.productIdentifier),
                let userId = userInfoProvider.userId else { return }
        
        processBuying(cards: bundle.cardsCount, for: userId) {
            if $0 {
                SKPaymentQueue.default().finishTransaction(transaction)
                NotificationCenter.default.post(name: Notification.Name.bundlePurchaseSucceded, object: self)
            }
        }
    }
    
    private func restored(transaction: SKPaymentTransaction) {
        guard let productId = transaction.original?.payment.productIdentifier,
            let bundle = bundle(for: productId),
            let userId = userInfoProvider.userId else { return }
        
        processBuying(cards: bundle.cardsCount, for: userId) {
            if $0 {
                SKPaymentQueue.default().finishTransaction(transaction)
                NotificationCenter.default.post(name: Notification.Name.bundlePurchaseSucceded, object: self)
            }
        }
    }
    
    private func deferred(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: Notification.Name.bundlePurchaseDeferred, object: self)
    }
    
    private func processBuying(cards count: Int, for user: String, completion: @escaping (Bool)->()) {
        Database.database().reference(withPath: "users/\(user)/purchases").runTransactionBlock({ (currentData) -> TransactionResult in
            if var purchases = currentData.value as? [String : Any] {
                var premCards = purchases["premiumCards"] as? Int ?? 0
                premCards += count
                purchases["premiumCards"] = premCards
                currentData.value = purchases
                return TransactionResult.success(withValue: currentData)
            } else {
                currentData.value = ["premiumCards" : count]
                return TransactionResult.success(withValue: currentData)
            }
        }, andCompletionBlock: { (error, commited, snapshot) in
            completion(commited)
        }, withLocalEvents: false)
    }
}


