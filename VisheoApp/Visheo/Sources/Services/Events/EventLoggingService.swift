//
//  EventLoggingService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/15/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase

protocol EventLoggingService: class {
	func log(event: EventRepresenting)
	func log(events: [EventRepresenting])
}


class VisheoEventLoggingService: EventLoggingService
{
	private let formatter: DateFormatter;
	
	init() {
		formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZ"
		formatter.timeZone = TimeZone(secondsFromGMT: 0);
	}
	
	func log(events: [EventRepresenting]) {
		for event in events {
			log(event: event);
		}
	}
	
	func log(event: EventRepresenting) {
		if event.logInternally {
			logInternalEvent(event);
		}
		
		if event.logToAnalytics {
			logToAnalytics(event: event);
		}
	}
	
	
	private func logToAnalytics(event: EventRepresenting) {
		Analytics.logEvent(event.type.rawValue, parameters: event.analyticsInfo);
	}
	
	
	private func logInternalEvent(_ event: EventRepresenting) {
		switch event {
			case let purchase as BundlePurchaseEvent:
				logPurchaseInternally(with: purchase);
			default:
				break;
		}
	}
	
	private func logPurchaseInternally(with event: BundlePurchaseEvent) {
		guard var info = event.internalInfo else {
			return;
		}
		
		info["transaction_date"] = formatter.string(from: event.date);
		
		let ref = Database.database().reference()
		let childUpdates = ["purchases/\(event.transactionId)" : info] as [String : Any]
		ref.updateChildValues(childUpdates)
	}
}
