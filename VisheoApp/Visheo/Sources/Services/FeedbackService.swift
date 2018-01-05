//
//  FeedbackService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import MessageUI
import UIKit
import SafariServices
import Firebase

extension Notification.Name {
	static let contactUsFeedbackSent = Notification.Name("contactUsFeedbackSent")
	static let contactUsFeedbackFailed = Notification.Name("contactUsFeedbackFailed")
}


enum FeedbackServiceError: Error {
	case setupMailClient
	case generic
	case underlying(error: Error)
}

enum FeedbackServiceNotificationKeys: String {
	case error
}

protocol FeedbackService: class {
	func showReviewChoice(on destination: UIViewController, onCancel: (() -> Void)?)
	func showContactForm(on destination: UIViewController)
	
	func didLeaveReview(_ cb: @escaping ((Bool) -> Void))
	func isReviewPending(_ cb: @escaping ((Bool) -> Void))
	func markReviewPending(_ cb: (() -> Void)?)
}

class VisheoFeedbackService: NSObject, FeedbackService {
	private enum ItunesAppId: String {
		case production = "1321534014"
		case staging = "1330216875"
	}
	
	private enum ReviewKeys: String {
		case reviewLastPresented = "review_last_presented"
		case reviewPending = "review_pending"
		case reviewChoice = "review_choice"
	}
	
	private let userInfoProvider: UserInfoProvider;
	
	init(userInfoProvider: UserInfoProvider) {
		self.userInfoProvider = userInfoProvider;
		super.init();
	}
	
	func showReviewChoice(on destination: UIViewController, onCancel: (() -> Void)? = nil) {
		let reviewAction = UIAlertAction(title: NSLocalizedString("Rate us now", comment: ""), style: .default) { [weak self] _ in
			self?.showReviewScreen(on: destination);
		}
		
		let feedbackAction = UIAlertAction(title: NSLocalizedString("Send us feedback", comment: ""), style: .default) { [weak self] _ in
			self?.showContactForm(on: destination, isReview: true);
		}
		
		let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .default) { _ in
			onCancel?();
		}
		
		let controller = UIAlertController(title: nil, message: NSLocalizedString("If you enjoy using Visheo, please rate us at AppStore! It won't take more than a minute. Thanks for your support!", comment: ""), preferredStyle: .alert);
		
		controller.addAction(reviewAction);
		controller.addAction(feedbackAction);
		controller.addAction(cancelAction);
		
		if let userId = userInfoProvider.userId {
			let ref = Database.database().reference().child("users/\(userId)")
			let childUpdates = [ ReviewKeys.reviewLastPresented.rawValue : round(Date().timeIntervalSince1970),
								 ReviewKeys.reviewPending.rawValue : false] as [String : Any]
			ref.updateChildValues(childUpdates)
		}
		
		destination.present(controller, animated: true, completion: nil);
	}
	
	func showContactForm(on destination: UIViewController) {
		showContactForm(on: destination, isReview: false)
	}
	
	private func showContactForm(on destination: UIViewController, isReview: Bool = false) {
		guard MFMailComposeViewController.canSendMail() else {
			let error = FeedbackServiceError.setupMailClient;
			NotificationCenter.default.post(name: .contactUsFeedbackFailed, object: self,
											userInfo: [ FeedbackServiceNotificationKeys.error : error ]);
			return;
		}
		
		let recipients = [ "visheoapp@gmail.com" ]
		let subject = NSLocalizedString("Visheo feedback", comment: "Contact us form mail subject");
		
		let mailController = MFMailComposeViewController();
		mailController.mailComposeDelegate = self;
		
		mailController.setToRecipients(recipients);
		mailController.setSubject(subject);
		if #available(iOS 11.0, *), let from = userInfoProvider.userEmail {
			mailController.setPreferredSendingEmailAddress(from)
		}
		
		if let userId = userInfoProvider.userId, isReview {
			let ref = Database.database().reference().child("users/\(userId)")
			let childUpdates = [ ReviewKeys.reviewChoice.rawValue : "feedback" ]
			ref.updateChildValues(childUpdates)
		}
		
		destination.present(mailController, animated: true, completion: nil);
	}
	
	
	private func showReviewScreen(on destination: UIViewController) {
		let appId = ItunesAppId.production.rawValue;
		let reviewURL = "itms-apps://itunes.apple.com/app/id\(appId)?action=write-review";
		guard let url = URL(string: reviewURL), UIApplication.shared.canOpenURL(url) else {
			return;
		}
		
		if let userId = userInfoProvider.userId {
			let ref = Database.database().reference().child("users/\(userId)")
			let childUpdates = [ ReviewKeys.reviewChoice.rawValue : "review" ]
			ref.updateChildValues(childUpdates)
		}
		
		UIApplication.shared.open(url, options: [:], completionHandler: nil)
	}
	
	func didLeaveReview(_ callback: @escaping ((Bool) -> Void)) {
		guard let userId = userInfoProvider.userId else {
			callback(false);
			return;
		}
		
		let ref = Database.database().reference().child("users/\(userId)");
		ref.observeSingleEvent(of: .value, with: { (snapshot) in
			if let `snapshot` = snapshot.value as? [String : Any], let _ = snapshot[ReviewKeys.reviewChoice.rawValue] {
				callback(true)
			} else {
				callback(false);
			}
		});
	}
	
	func isReviewPending(_ callback: @escaping ((Bool) -> Void)) {
		guard let userId = userInfoProvider.userId else {
			callback(false);
			return;
		}
		
		let ref = Database.database().reference().child("users/\(userId)")
		ref.observeSingleEvent(of: .value, with: { (snapshot) in
			guard let `snapshot` = snapshot.value as? [String : Any] else {
				callback(false)
				return;
			}
			if let _ = snapshot[ReviewKeys.reviewChoice.rawValue] {
				callback(false);
				return;
			}
			let pending = (snapshot[ReviewKeys.reviewPending.rawValue] as? NSNumber)?.boolValue ?? false;
			callback(pending);
		});
	}
	
	func markReviewPending(_ callback: (() -> Void)?) {
		guard let userId = userInfoProvider.userId else {
			return;
		}
		
		let ref = Database.database().reference().child("users/\(userId)");
		ref.observeSingleEvent(of: .value, with: { (snapshot) in
			if let `snapshot` = snapshot.value as? [String : Any], let _ = snapshot[ReviewKeys.reviewChoice.rawValue] {
				callback?()
				return;
			}
			let updates = [ ReviewKeys.reviewPending.rawValue : true ]
			ref.updateChildValues(updates);
			callback?()
		})
	}
}


extension VisheoFeedbackService: MFMailComposeViewControllerDelegate {
	func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
		controller.dismiss(animated: true) {
			switch result {
				case .sent:
					NotificationCenter.default.post(name: .contactUsFeedbackSent, object: self);
				case .failed:
					var err = FeedbackServiceError.generic;
					if let e = error {
						err = FeedbackServiceError.underlying(error: e);
					}
					NotificationCenter.default.post(name: .contactUsFeedbackFailed, object: self,
													userInfo: [ FeedbackServiceNotificationKeys.error : err ]);
				default:
					break;
			}
		}
	}
}
