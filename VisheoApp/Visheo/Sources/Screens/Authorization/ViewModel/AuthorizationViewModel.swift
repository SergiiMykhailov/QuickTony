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
    case inviteFriends
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
    var shouldShowTermsOfUse : Bool { get }
    
    func signIn()
    func signUp()
    
    func cancel()
    
    var getPresentationViewController : (() -> (UIViewController?))? {get set}
    var didChange : (()->())? {get set}
    
    var cancelAllowed : Bool {get}
    var descriptionString : String? {get}
	
	var closeButtonType: AuthorizationDismissType? { get }
}

class VisheoAutorizationViewModel : AuthorizationViewModel {
    var cancelAllowed: Bool {
        return authReason != .none
    }
    
    var shouldShowTermsOfUse: Bool {
        return appState.isTermsOfUseHidden
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
            case .inviteFriends:
                return NSLocalizedString("Please sign in to invite friends", comment: "Please sign in to invite friends")
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
    
    var didChange : (()->())?
    var warningAlertHandler: ((String) -> ())?
    var getPresentationViewController: (() -> (UIViewController?))?
    var showProgressCallback: ((Bool) -> ())?
    let anonymousAllowed : Bool
    let userNotificationService: UserNotificationsService
    let invitesService: InvitesService
	private let authReason : AuthorizationReason
    private let appState : AppStateService
    
    weak var router: AuthorizationRouter?
    var authService : AuthorizationService
    
    init(authService: AuthorizationService,
         anonymousAllowed: Bool,
         authReason: AuthorizationReason,
         userNotificationService: UserNotificationsService,
         invitesService: InvitesService,
         appStateService: AppStateService) {
		self.authReason = authReason
        self.authService = authService
        self.anonymousAllowed = anonymousAllowed
        self.userNotificationService = userNotificationService
        self.invitesService = invitesService
        self.appState = appStateService
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.termsOfUseHiddenChanged, object: nil, queue: OperationQueue.main) { [weak self] _ in
            self?.didChange?()
        }
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
        
        if (!authService.isAnonymous) {
            userNotificationService.registerNotifications()
            invitesService.handleAuthorization()
        }
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
