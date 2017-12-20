//
//  FeedbackService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import MessageUI
import UIKit

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
	func showContactForm(from contact: String?, on destination: UIViewController)
}

class VisheoFeedbackService: NSObject, FeedbackService
{
	func showContactForm(from contact: String?, on destination: UIViewController) {
		guard MFMailComposeViewController.canSendMail() else {
			let error = FeedbackServiceError.setupMailClient;
			NotificationCenter.default.post(name: .contactUsFeedbackFailed, object: self,
											userInfo: [ FeedbackServiceNotificationKeys.error : error ]);
			return;
		}
		
		let recipients = [ "alexmahtin@gmail.com", "oleksiy.n@gmail.com" ]
		let subject = NSLocalizedString("Visheo feedback", comment: "Contact us form mail subject");
		
		let mailController = MFMailComposeViewController();
		mailController.mailComposeDelegate = self;
		
		mailController.setToRecipients(recipients);
		mailController.setSubject(subject);
		if #available(iOS 11.0, *), let from = contact {
			mailController.setPreferredSendingEmailAddress(from)
		}
		destination.present(mailController, animated: true, completion: nil);
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
