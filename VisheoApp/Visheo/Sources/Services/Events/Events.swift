//
//  Events.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/15/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


enum EventType: String {
	case userRegistered = "user_registered"
	case regularCardSent = "regular_card_sent"
	case premiumCardSent = "premium_card_sent"
	case smallBundlePurchased = "S_bundle_purchase"
	case bigBundlePurchased = "L_bundle_purchase"
	case couponRedeemed = "coupon_redeemed"
}

protocol EventRepresenting {
	var type: EventType { get }
	
	var logToAnalytics: Bool { get }
	var logInternally: Bool { get }
	
	var analyticsInfo: [ String : Any ]? { get }
	var internalInfo: [ String : Any ]? { get }
}

extension EventRepresenting {
	var analyticsInfo: [ String : Any ]? { return nil }
	var internalInfo: [ String : Any ]? { return nil }
	
	var logToAnalytics: Bool { return true }
	var logInternally: Bool { return false }
	
}


struct RegistrationEvent: EventRepresenting {
	let userId: String;
	let provider: String;
	
	var type: EventType {
		return .userRegistered;
	}
	
	var analyticsInfo: [String : Any]? {
		return [ "user_id" : userId,
				 "provider" : provider ]
	}
}


struct CardSentEvent: EventRepresenting {
	let isPremium: Bool
	
	var type: EventType {
		return isPremium ? .premiumCardSent : .regularCardSent
	}
}


struct BundlePurchaseEvent: EventRepresenting {
	let userId: String;
	let transactionId: String;
	let productId: String;
	let date: Date;
	let amount: Int;
	let isBigBundle: Bool;
	
	var type: EventType {
		return isBigBundle ? .bigBundlePurchased : .smallBundlePurchased;
	}
	
	var analyticsInfo: [String : Any]? {
		return [ "user_id" : userId ]
	}
	
	var internalInfo: [String : Any]? {
		return [ "user_id" : userId,
				 "transaction_id" : transactionId,
				 "product_id" : productId,
				 "transaction_date" : date,
				 "amount" : amount,
				 "event" : type.rawValue
			]
	}
	
	var logInternally: Bool {
		return true;
	}
}


struct CouponRedeemedEvent: EventRepresenting {
	var type: EventType {
		return .couponRedeemed;
	}
}
