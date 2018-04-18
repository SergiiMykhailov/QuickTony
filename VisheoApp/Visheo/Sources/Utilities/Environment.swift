//
//  Environment.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import Firebase
import SwiftyStoreKit

enum Environment {
	case staging
	case production
	
	static var current: Environment {
		if let useStaging = (Bundle.main.infoDictionary?["UseStagingEnvironment"] as? NSNumber)?.boolValue, useStaging {
			return .staging;
		}
		return .production;
	}
	
}

fileprivate enum StoragePaths {
    static let premium     = "RegularVisheo"
    static let free        = "PublicVisheo"
}


extension Environment {
	func storageRef(for id: String, premium: Bool) -> StorageReference {
		switch self {
			case .staging:
				return StagingStorageBuckets.storageRef(for: id, premium: premium);
			case .production:
				return ProductionStorageBuckets.storageRef(for: id, premium: premium);
		}
	}
    
    func appleStoreValidator() -> AppleReceiptValidator {
        switch self {
            case .staging:
                return AppleReceiptValidator(service: .sandbox,
                                             sharedSecret: "90a37c89dd074e0f943a973ac952d3c2")
            case .production:
                return AppleReceiptValidator(service: .production,
                                             sharedSecret: "18666539d51048d19fb79bbbf4798628")
        }
    }
    
    func inviteURL () -> String {
        switch self {
        case .staging:
            return "aj6fz"
        case .production:
            return "q877w"
        }
    }
}


protocol StorageBuckets {
	static func storageRef(for id: String, premium: Bool) -> StorageReference
    static func bucketUrl() -> String
    static func storagePath(premium: Bool) -> String
}

extension StorageBuckets {
    static func storageRef(for id: String, premium: Bool) -> StorageReference {
        let path = self.storagePath(premium: premium)
        let url = self.bucketUrl()
        let child = path + "/" + id;
        let storageRef = Storage.storage(url: url).reference().child(child)
        return storageRef
    }
    
    static func storagePath(premium: Bool) -> String {
        return premium ? StoragePaths.premium : StoragePaths.free
    }
}

struct StagingStorageBuckets: StorageBuckets {
    static func bucketUrl() -> String {
        return "gs://visheo-staging.appspot.com"
    }
}

struct ProductionStorageBuckets: StorageBuckets {
    static func bucketUrl() -> String {
        return "gs://visheo42freecards"
    }
}
