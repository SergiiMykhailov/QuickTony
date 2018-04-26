//
//  Events.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/15/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

enum EventType: String {
	case userRegistered         = "user_registered"
	case regularCardSent        = "regular_card_sent"
	case premiumCardSent        = "premium_card_sent"
	case smallBundlePurchased   = "S_bundle_purchase"
	case bigBundlePurchased     = "L_bundle_purchase"
    case subsctiptionPurchased  = "subscription_purchase"
	case couponRedeemed         = "coupon_redeemed"
	case reminderSet            = "remind_later"
	case linkCopied             = "link_copied"
	case linkShared             = "visheo_shared"
	case coverSelected          = "cover_selected"
	case photosSelected         = "selected_photos"
	case photosSkipped          = "skipped_photos"
	case reachedPreview         = "reached_preview_screen"
	case soundtrackChanged      = "soundtrack_changed"
	case retakeVideo            = "retake_video"
    case visheoDownloaded       = "downloaded"
    case visheoSaved            = "visheo_save_click"
    case visheoUploaded         = "visheo_uploaded"
    case descriptionChanged     = "description_changed"
    case bestPracticesClicked   = "best_practices_clicked"
    case onboardingPassed       = "onboarding_passed"
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
		return isBigBundle ? .bigBundlePurchased : .smallBundlePurchased
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

struct SubscriptionPurchaseEvent: EventRepresenting {
    let userId: String
    let transactionId: String
    let productId: String
    let date: Date
    let expiresIn: Int
    
    var type: EventType {
        return .subsctiptionPurchased
    }
    
    var analyticsInfo: [String : Any]? {
        return [ "user_id" : userId ]
    }
    
    var internalInfo: [String : Any]? {
        return ["user_id" : userId,
                "transaction_id" : transactionId,
                "product_id" : productId,
                "transaction_date" : date,
                "expires_in" : expiresIn]
    }
    
    var logInternally: Bool{
        return true
    }
}

struct CouponRedeemedEvent: EventRepresenting {
	var type: EventType {
		return .couponRedeemed;
	}
}

struct ReminderEvent: EventRepresenting {
	var type: EventType {
		return .reminderSet;
	}
}

struct VisheoURLCopiedEvent: EventRepresenting {
	var type: EventType {
		return .linkCopied;
	}
}

struct VisheoSharedEvent: EventRepresenting {
	var type: EventType {
		return .linkShared;
	}
}

struct CoverSelectedEvent: EventRepresenting {
	var type: EventType {
		return .coverSelected;
	}
}

struct PhotosSelectedEvent: EventRepresenting {
	let count: Int
	
	var type: EventType {
		return .photosSelected;
	}
	
	var analyticsInfo: [String : Any]? {
		return [ "count" : count ]
	}
}

struct PhotosSkippedEvent: EventRepresenting {
	var type: EventType {
		return .photosSkipped;
	}
}

struct ReachedPreviewEvent: EventRepresenting {
	var type: EventType {
		return .reachedPreview;
	}
}

struct SoundtrackChangedEvent: EventRepresenting {
	var type: EventType {
		return .soundtrackChanged;
	}
}

struct RetakeVideoEvent: EventRepresenting {
	var type: EventType {
		return .retakeVideo;
	}
}

struct VisheoDownloadEvent: EventRepresenting {
    var type: EventType {
        return .visheoDownloaded
    }
}

struct VisheoSaved: EventRepresenting {
    var type: EventType {
        return .visheoSaved
    }
}

struct VisheoUploaded: EventRepresenting {
    var type: EventType {
        return .visheoUploaded
    }
}

struct DescriptionChanged: EventRepresenting {
    var type: EventType {
        return .descriptionChanged
    }
}

struct BestPracticesClicked: EventRepresenting {
    var type: EventType {
        return .bestPracticesClicked
    }
}

struct OnboardingPassed: EventRepresenting {
    var type: EventType {
        return .onboardingPassed
    }
}
