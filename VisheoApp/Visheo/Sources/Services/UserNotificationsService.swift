//
//  NotificationService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/5/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import UserNotifications
import PromiseKit

enum UserNotificationsServiceError: Error
{
	case other(error: Error)
	case authorizationDenied
}

enum UserNotificationsServiceNotificationKeys: String {
	case id
}

extension Notification.Name {
	static let openVisheoFromReminder = Notification.Name("openVisheoFromReminder")
}

protocol UserNotificationsService {
	func schedule(at date: Date, text: String, visheoId: String, completion: ((Error?) -> Void)?)
    func registerNotifications()
}

class VisheoUserNotificationsService: NSObject, UserNotificationsService, UNUserNotificationCenterDelegate
{
	override init() {
		super.init();
		UNUserNotificationCenter.current().delegate = self;
	}
	
	func schedule(at date: Date, text: String, visheoId: String, completion: ((Error?) -> Void)?)
	{
		let content = UNMutableNotificationContent();
		content.title = text;
		
		let calendar = Calendar(identifier: .gregorian);
		let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date);
		
		let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false);
		let request = UNNotificationRequest(identifier: visheoId, content: content, trigger: trigger);
		
		UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [visheoId]);
		
		let promise = addRequest(request);
		
		firstly {
			execute(action: promise)
		}
		.then { _ in
			completion?(nil);
		}.catch { e in
			completion?(e);
		}
	}
	
	private func execute<T>(action: Promise<T>) -> Promise<T>
	{
		return firstly {
			fetchAuthorizationStatus()
		}
		.then { status -> Promise<Bool> in
			switch status {
				case .notDetermined:
					return self.requestAuthorization();
				case .authorized:
					return Promise(value: true);
				case .denied:
					return Promise(value: false);
			}
		}
		.then { authorized -> Promise<T> in
			if authorized {
				return action;
			}
			throw UserNotificationsServiceError.authorizationDenied;
		}
		.recover{ error -> Promise<T> in
			if case UserNotificationsServiceError.authorizationDenied = error {
				throw error;
			}
			throw UserNotificationsServiceError.other(error: error);
		}
	}
	
	private func requestAuthorization() -> Promise<Bool> {
		return Promise { fl, rj in
			UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound], completionHandler: { (granted, error) in
				if let e = error {
					rj(e)
				} else {
					fl(granted);
				}
			})
		}
	}
	
	private func fetchAuthorizationStatus() -> Promise<UNAuthorizationStatus> {
		return Promise{ fl, rj in
			UNUserNotificationCenter.current().getNotificationSettings(completionHandler: { (settings) in
				fl(settings.authorizationStatus)
			})
		}
	}
	
	private func addRequest(_ request: UNNotificationRequest) -> Promise<Void> {
		return Promise { fl, rj in
			UNUserNotificationCenter.current().add(request) { (error) in
				if let e = error {
					rj(e);
				} else {
					fl(Void());
				}
			}
		}
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		completionHandler([.alert, .sound]);
	}
	
	func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
		let visheoId = response.notification.request.identifier;
		let info = [ UserNotificationsServiceNotificationKeys.id : visheoId ];
		NotificationCenter.default.post(name: .openVisheoFromReminder, object: self, userInfo: info);
		completionHandler();
	}
    
    func registerNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
        UIApplication.shared.registerForRemoteNotifications()
    }
}
