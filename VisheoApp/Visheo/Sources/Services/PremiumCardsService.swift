//
// Created by Petro Kolesnikov on 12/6/17.
// Copyright (c) 2017 Olearis. All rights reserved.
//

import Foundation
import StoreKit
import Firebase
import SwiftyStoreKit

extension Notification.Name {
    static let premiumBundlesLoaded = Notification.Name("premiumBundlesLoaded")
    static let loadingPremiumBundlesFailed = Notification.Name("loadingPremiumBundlesFailed")
    
    static let bundlePurchaseFailed = Notification.Name("bundlePurchaseFailed")
    static let bundlePurchaseCancelled = Notification.Name("bundlePurchaseCancelled")
    static let bundlePurchaseSucceded = Notification.Name("bundlePurchaseSucceded")
    static let bundlePurchaseDeferred = Notification.Name("bundlePurchaseDeferred")
    
    static let userPremiumCardsCountChanged = Notification.Name("userPremiumCardsCountChanged")
    static let userSubscriptionStateChanged = Notification.Name("userSubscriptionStateChanged")
}

enum RedeemError : Error {
    case unknown
    case invalidCoupon
    case expired
    case exceededLimit
    case alreadyRedeemed
}

enum SubscriptionState : Int {
    case none
    case active
    case expired
}

protocol UserPurchasesInfo {
    var currentUserPremiumCards : Int {get}
    
    func currentUserSubscriptionState() -> SubscriptionState
    func currentUserSubscriptionExpireDate() -> String
}

protocol PremiumCardsService {
    func reloadPurchases()
    var smallBundle : PremiumCardsBundle? {get}
    var bigBundle : PremiumCardsBundle? {get}
    var subscription : PremiumSubsctription? {get}
    
    func buy(bundle: PurchaseBase)
    func redeem(coupon: String, completion: @escaping (Int?, RedeemError?)->())
    
    func usePremiumCard(completion: @escaping (Bool)->())
    func currentUserSubscriptionState() -> SubscriptionState
    func checkSubscriptionStateRemotely(withCompletion completionBlock:@escaping ((VerifySubscriptionResult?, Error?) -> Void))
}

class PurchaseBase {
    var price : NSDecimalNumber? {
        return skProduct?.price
    }
    
    var priceLocale : Locale? {
        return skProduct?.priceLocale
    }
    
    var description : String? {
        return skProduct?.localizedDescription
    }
    
    fileprivate let productId : String
    fileprivate var skProduct : SKProduct?
    
    fileprivate init?(snapshot: DataSnapshot?) {
        guard let snapshot = snapshot,
            let productId = snapshot.childSnapshot(forPath:"appleId").value as? String else {return nil}
        
        self.productId = productId
    }
    
    fileprivate func update(with product: SKProduct) {
        skProduct = product
    }
}

class PremiumCardsBundle : PurchaseBase {
    
    fileprivate let cardsCount : Int
    
    override fileprivate init?(snapshot: DataSnapshot?) {
        guard let snapshot = snapshot,
            let cardsCount = snapshot.childSnapshot(forPath: "cardsCount").value as? Int else {return nil}
        
        self.cardsCount = cardsCount
        
        super.init(snapshot: snapshot)
    }
}

class PremiumSubsctription : PurchaseBase {
    fileprivate let expires : Int
    
    override init?(snapshot: DataSnapshot?) {
        guard let snapshot = snapshot,
            let expirationPeriod = snapshot.childSnapshot(forPath: "expirationPeriod").value as? Int else {return nil}
        
        self.expires = expirationPeriod
        
        super.init(snapshot: snapshot)
    }
}

class VisheoPremiumCardsService : NSObject, PremiumCardsService, UserPurchasesInfo, SKProductsRequestDelegate, SKPaymentTransactionObserver {
    enum Constants {
        static let smallBundleId = "cardPacks/smallCardsPack"
        static let bigBundleId = "cardPacks/bigCardsPack"
        static let subscription = "subscriptions/subscription"
    }
    
    var subscription: PremiumSubsctription?
    var smallBundle: PremiumCardsBundle?
    var bigBundle: PremiumCardsBundle?
    
    var currentUserPremiumCards: Int {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.userPremiumCardsCountChanged, object: self)
        }
    }
    
    private var expireDate: Date? {
        didSet {
            NotificationCenter.default.post(name: Notification.Name.userSubscriptionStateChanged, object: self)
        }
    }
    
    func currentUserSubscriptionState() -> SubscriptionState {
        guard let expireDate = expireDate else { return .none }
        
        if (expireDate >= Date()) {
            return .active
        }
        return .expired
    }
    
    func currentUserSubscriptionExpireDate() -> String {
        guard let expireDate = expireDate else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
        dateFormatter.timeZone = TimeZone.current
        return dateFormatter.string(from: expireDate)
    }
    
    func checkSubscriptionStateRemotely(withCompletion completionBlock:@escaping ((VerifySubscriptionResult?, Error?) -> Void)) {
        if let productId = subscription?.productId {
            let appStoreValidator = Environment.current.appleStoreValidator()
            
            SwiftyStoreKit.verifyReceipt(using: appStoreValidator) {[weak self] result in
                switch result {
                case .success(let receipt):
                    let purchaseResult = SwiftyStoreKit.verifySubscription(
                        ofType: .autoRenewable,
                        productId: productId,
                        inReceipt: receipt)
                    
                    switch purchaseResult {
                        case .purchased(_, let items):
                            guard let `self` = self,
                                let item = items.first,
                                let userId = self.userInfoProvider.userId else { return }
                            
                            self.processSubscribing(withDate: item.subscriptionExpirationDate!, forTranId: item.originalTransactionId, user: userId, completion: {
                                if $0 {
                                    NotificationCenter.default.post(name: .bundlePurchaseSucceded, object: self, userInfo: nil)
                                }
                            })
                            break;
                        default:
                            break;
                    }
                    
                    completionBlock(purchaseResult, nil)
                    
                case .error(let error):
                    completionBlock(nil, error)
                }
            }
        }
    }
    
    private var productsRequest : SKProductsRequest?
    private let userInfoProvider : UserInfoProvider
	private let loggingService: EventLoggingService
    
    private var premCardsReference : DatabaseReference?
    private var subscriptionReference : DatabaseReference?
    
	init(userInfoProvider: UserInfoProvider, loggingService: EventLoggingService) {
        self.userInfoProvider = userInfoProvider
		self.loggingService = loggingService;
        currentUserPremiumCards = 0
        super.init()
        loadPurchases()
        startPremiumCardsObserving()
        SKPaymentQueue.default().add(self)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.authStateChanged, object: nil, queue: OperationQueue.main) { (notification) in
            self.currentUserPremiumCards = 0
            self.startPremiumCardsObserving()
            self.startSubscriptionObserving()
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
    
    private func startSubscriptionObserving(){
        if let oldReference = subscriptionReference {
            oldReference.removeAllObservers()
        }
        
        if let userId = userInfoProvider.userId {
            let userSubscriptionRef = Database.database().reference(withPath: "users/\(userId)/purchases/subscriptionExpireDate")
            subscriptionReference = userSubscriptionRef
            
            userSubscriptionRef.observe(.value, with: { (snapshot) in
                guard let dateAsString = snapshot.value as? String else { self.expireDate = nil; return }
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
                dateFormatter.timeZone = TimeZone.current
                self.expireDate = dateFormatter.date(from: dateAsString)
            })
        }
    }
    
    func reloadPurchases() {
        loadPurchases()
    }
    
    func buy(bundle: PurchaseBase) {
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
            Database.database().reference(withPath: "coupons/\(couponId)/").runTransactionBlock({ (currentData) -> Firebase.TransactionResult in
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
        Database.database().reference(withPath: "availablePurchases_2_0").observe(.value) { (snapshot) in
            self.smallBundle = PremiumCardsBundle(snapshot: snapshot.childSnapshot(forPath: Constants.smallBundleId))
            self.bigBundle   = PremiumCardsBundle(snapshot: snapshot.childSnapshot(forPath: Constants.bigBundleId))
            self.subscription = PremiumSubsctription(snapshot: snapshot.childSnapshot(forPath: Constants.subscription))
            
            var products = Set<String>()
            if let smallId = self.smallBundle?.productId {products.insert(smallId)}
            if let bigId = self.bigBundle?.productId {products.insert(bigId)}
            if let subscriptionId = self.subscription?.productId {products.insert(subscriptionId)}
            self.startProductrequest(for: products)
        }
    }
    
    private func startProductrequest(for products: Set<String>) {
        productsRequest = SKProductsRequest(productIdentifiers: products)
        productsRequest?.delegate = self
        productsRequest?.start()
    }
    
    private func bundle(for productId: String) -> PurchaseBase? {
        if productId == self.bigBundle?.productId {
            return self.bigBundle
        }
        if productId == self.smallBundle?.productId {
            return self.smallBundle
        }
        if productId == self.subscription?.productId{
            return self.subscription
        }
        return nil
    }
    
    private func spendCard(for user: String, completion: @escaping (Bool)->()) {
        Database.database().reference(withPath: "users/\(user)/purchases").keepSynced(true)
        Database.database().reference(withPath: "users/\(user)/purchases").observeSingleEvent(of: .value) { (snapshot) in
            Database.database().reference(withPath: "users/\(user)/purchases").runTransactionBlock({ (currentData) -> Firebase.TransactionResult in
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
        guard let product = bundle(for: transaction.payment.productIdentifier),
                let userId = userInfoProvider.userId else { return }
        
        registerSucceedProduct(forTransaction:transaction, product: product, userId: userId)
    }
    
    private func restored(transaction: SKPaymentTransaction) {
        guard let productId = transaction.original?.payment.productIdentifier,
            let product = bundle(for: productId),
            let userId = userInfoProvider.userId else { return }
        
        registerSucceedProduct(forTransaction:transaction, product: product, userId: userId)
    }
    
    private func registerSucceedProduct(forTransaction transaction:SKPaymentTransaction, product:PurchaseBase, userId: String) {
        if let bundle = product as? PremiumCardsBundle {
            processBuying(cards: bundle.cardsCount, for: userId) {
                if $0 {
                    self.logPurchaseEvent(userId: userId, bundle: bundle, transaction: transaction)
                    SKPaymentQueue.default().finishTransaction(transaction)
                    NotificationCenter.default.post(name: .bundlePurchaseSucceded, object: self, userInfo: [ "count" : bundle.cardsCount ])
                }
            }
        }
        
        if let bundle = product as? PremiumSubsctription {
            checkSubscriptionStateRemotely(withCompletion: { [weak self] purchaseResult, error in
                if let purchaseResult = purchaseResult {
                    switch purchaseResult {
                        case .purchased(_,_):
                            self?.logSubscriptionEvent(userId: userId, bundle: bundle, transaction: transaction)
                            SKPaymentQueue.default().finishTransaction(transaction)
                            break;
                        default:
                            break;
                    }
                } else if let error = error {
                    //TODO: error handle
                    print(error)
                }
            })
        }
    }
    
    private func deferred(transaction: SKPaymentTransaction) {
        NotificationCenter.default.post(name: Notification.Name.bundlePurchaseDeferred, object: self)
    }
    
    private func processBuying(cards count: Int, for user: String, completion: @escaping (Bool)->()) {
        Database.database().reference(withPath: "users/\(user)/purchases").runTransactionBlock({ (currentData) -> Firebase.TransactionResult in
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
	
    private func processSubscribing(withDate expDate: Date, forTranId: String, user: String, completion: @escaping (Bool)->()) {
        Database.database().reference(withPath: "users/\(user)/purchases").runTransactionBlock({ (currentData) -> Firebase.TransactionResult in
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
            dateFormatter.timeZone = TimeZone.current
            currentData.value = ["subscriptionExpireDate" : dateFormatter.string(from: expDate),
                                 "subscriptionTransactionId" : forTranId]
            return TransactionResult.success(withValue: currentData)
        }, andCompletionBlock: { (error, commited, snapshot) in
            completion(commited)
        }, withLocalEvents: false)
    }
    
	private func logPurchaseEvent(userId: String, bundle: PremiumCardsBundle, transaction: SKPaymentTransaction) {
		guard let date = transaction.transactionDate, let id = transaction.transactionIdentifier else { return }
		let isBigBundle = (bundle.productId == self.bigBundle?.productId)
		let event = BundlePurchaseEvent(userId: userId,
										transactionId: id,
										productId: bundle.productId,
										date: date,
										amount: bundle.cardsCount,
										isBigBundle: isBigBundle)
		loggingService.log(event: event)
	}
    
    private func logSubscriptionEvent(userId: String, bundle: PremiumSubsctription, transaction: SKPaymentTransaction){
        guard let date = transaction.transactionDate, let id = transaction.transactionIdentifier else { return }
        let event = SubscriptionPurchaseEvent(userId: userId,
                                              transactionId: id,
                                              productId: bundle.productId,
                                              date: date,
                                              expiresIn: bundle.expires)
        loggingService.log(event: event)
    }
}


