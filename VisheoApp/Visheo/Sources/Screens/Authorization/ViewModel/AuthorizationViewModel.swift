//
//  AuthorizationViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit


enum AuthorizationReason {
	case none
	case premiumCards
	case redeemCoupons
	case sendFeedback
	case sendVisheo
}

enum AuthorizationDismissType {
	case back
	case close
}

protocol AuthorizationViewModel : class, ProgressGenerating, WarningAlertGenerating {
    func loginWithGoogle()
    func loginWithFacebook()
    func loginAsAnonymous()
    
    var anonymousAllowed : Bool { get }
    
    func signIn()
    func signUp()
    
    func cancel()
    
    var getPresentationViewController : (() -> (UIViewController?))? {get set}
    
    var cancelAllowed : Bool {get}
    var descriptionString : String? {get}
	
	var closeButtonType: AuthorizationDismissType? { get }
}

class VisheoAutorizationViewModel : AuthorizationViewModel {
    var cancelAllowed: Bool {
        return authReason != .none
    }
    
    var descriptionString: String? {
		switch authReason {
			case .premiumCards:
				return NSLocalizedString("Please sign in to purchase premium cards", comment: "Please sign in to purchase premium cards")
			case .redeemCoupons:
				return NSLocalizedString("Please sign in to redeem coupons", comment: "Please sign in to redeem coupons")
			case .sendFeedback:
				return NSLocalizedString("Please sign in to send feedback", comment: "Please sign in to send feedback")
			case .sendVisheo:
				return NSLocalizedString("SIGN UP TO SEND YOUR VISHEO", comment: "SIGN UP TO SEND YOUR VISHEO")
			default:
				return nil
		}
    }
	
	var closeButtonType: AuthorizationDismissType? {
		if (!cancelAllowed) {
			return nil;
		}
		
		switch authReason {
			case .sendVisheo:
				return .back;
			default:
				return .close;
		}
	}
    
    var warningAlertHandler: ((String) -> ())?
    var getPresentationViewController: (() -> (UIViewController?))?
    var showProgressCallback: ((Bool) -> ())?
    let anonymousAllowed : Bool
	private let authReason : AuthorizationReason;
    
    weak var router: AuthorizationRouter?
    var authService : AuthorizationService
    
	init(authService: AuthorizationService, anonymousAllowed: Bool, authReason: AuthorizationReason) {
		self.authReason = authReason
        self.authService = authService
        self.anonymousAllowed = anonymousAllowed
    }
    
    deinit {
        stopAuthObserving()
    }
    
    func loginWithGoogle() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.loginWithGoogle(from: getPresentationViewController?())
    }
    
    func loginWithFacebook() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.loginWithFacebook(from: getPresentationViewController?())
    }
    
    func loginAsAnonymous() {
        showProgressCallback?(true)
        startAuthObserving()
        authService.loginAsAnonymous()
    }
    
    func signIn() {
        router?.showSignIn()
    }
    
    func signUp() {
        router?.showSignUp()
    }
    
    func cancel() {
        router?.close()
    }
    
    @objc func processLogin() {
        showProgressCallback?(false)
        stopAuthObserving()
        router?.showMainScreen()
    }
    
    @objc func processLoginFail(notification: Notification) {
        stopAuthObserving()
        self.showProgressCallback?(false)
        if case .unknownError(let description)? = notification.userInfo?[Notification.Keys.error] as? AuthError {
            self.warningAlertHandler?(description)
        }
    }
    
    private func startAuthObserving() {
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoAutorizationViewModel.processLogin), name: .userLoggedIn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoAutorizationViewModel.processLoginFail(notification:)), name: .userLoginFailed, object: nil)
    }
    
    private func stopAuthObserving() {
        NotificationCenter.default.removeObserver(self)
    }
}
