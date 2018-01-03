//
//  Environment.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import Firebase

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

extension Environment {
	func storageRef(for id: String, premium: Bool) -> StorageReference {
		switch self {
			case .staging:
				return StagingStorageBuckets.storageRef(for: id, premium: premium);
			case .production:
				return ProductionStorageBuckets.storageRef(for: id, premium: premium);
		}
	}
}


protocol StorageBuckets {
	static func storageRef(for id: String, premium: Bool) -> StorageReference
}


struct StagingStorageBuckets: StorageBuckets {
	private enum StoragePaths {
		static let premium     = "PremiumVisheos"
		static let free        = "FreeVisheos"
	}
	
	static func storageRef(for id: String, premium: Bool) -> StorageReference {
		let path = premium ? StoragePaths.premium : StoragePaths.free
		let url = "gs://visheo-staging.appspot.com"
		let child = path + "/" + id;
		let storageRef = Storage.storage(url: url).reference().child(child)
		return storageRef
	}
}

struct ProductionStorageBuckets: StorageBuckets {
	private enum StorageBuckets {
		static let premium     = "gs://visheo42premiumcards"
		static let free        = "gs://visheo42freecards"
	}
	
	static func storageRef(for id: String, premium: Bool) -> StorageReference {
		let bucket = premium ? StorageBuckets.premium : StorageBuckets.free
		
		let storagePath = "\(bucket)"
		
		let storageRef = Storage.storage(url: storagePath).reference().child("\(id)")
		return storageRef
	}
}
