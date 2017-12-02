//
//  File.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase
import GoogleSignIn
import FBSDKLoginKit

protocol AuthorizationService {
    var isAuthorized : Bool {get}
    var isAnonymous : Bool {get}
    
    func loginWithFacebook(from vc: UIViewController?)
    func loginWithGoogle(from vc: UIViewController?)
    func loginAsAnonymous()
    
    func signUp(with email: String, password: String, fullName: String)
    func signIn(with email: String, password: String)
    
    func sendResetPassword(for email: String, completion : ((AuthError?) -> ())?)
}

protocol UserInfoProvider {
    var userId: String? {get}
    
    var userName: String? {get}
    var userPicUrl: URL? {get}
}

extension Notification.Name {
    static let userLoggedIn = Notification.Name("userLoggedIn")
    static let userLoginFailed = Notification.Name("userLoginFailed")
    static let authStateChanged = Notification.Name("authStateChanged")
}

extension Notification {
    enum Keys {
        static let error = "Error"
    }
}

enum AuthError: Error {
    case cancelled
    case unknownError(description : String)
}

class VisheoAuthorizationService : NSObject, AuthorizationService, UserInfoProvider {
    private let appState : AppStateService
    
    init(appState: AppStateService) {
        self.appState = appState
        super.init()
        setupGoogleDependencies()

        if appState.firstLaunch {
            try? Auth.auth().signOut()
        }
        
        Auth.auth().addStateDidChangeListener {[weak self] (auth, user) in
            if let `self` = self {
                NotificationCenter.default.post(name: .authStateChanged, object: self)
            }
        }
    }
    
    var userId: String? {
        return Auth.auth().currentUser?.uid
    }
    
    var userName: String? {
        return Auth.auth().currentUser?.displayName
    }
    
    var userPicUrl: URL? {
        return Auth.auth().currentUser?.photoURL
    }
    
    var isAuthorized: Bool  {        
        return Auth.auth().currentUser != nil
    }
    
    var isAnonymous: Bool  {
        return Auth.auth().currentUser?.isAnonymous ?? true
    }
    
    weak var presentationViewController : UIViewController?
    
    func notifyLogin() {
        NotificationCenter.default.post(name: .userLoggedIn, object: self)
    }
    
    func notifyLoginFail(error: AuthError) {
        NotificationCenter.default.post(name: .userLoginFailed, object: self, userInfo: [Notification.Keys.error : error])
    }
}

// MARK: Firebase auth

extension VisheoAuthorizationService {
    func loginAsAnonymous() {
        Auth.auth().signInAnonymously { (user, error) in
            if let error = error {
                self.notifyLoginFail(error: .unknownError(description: error.localizedDescription))
            } else {
                self.notifyLogin()
            }
        }
    }
    
    func signUp(with email: String, password: String, fullName: String) {
        Auth.auth().createUser(withEmail: email,
                               password: password) { (user, error) in
                                if let user = user {
                                    let changeRequest = user.createProfileChangeRequest()
                                    changeRequest.displayName = fullName
                                    
                                    user.sendEmailVerification(completion: { (error) in
                                        //TODO: Handle email verification fail (save status before sendign and cehck it on every start)
                                    })
                                    changeRequest.commitChanges { (error) in
                                        //TODO: Handle full name setup fail (save full name before sendign and resend it of failed on every start)
                                    }
                                    self.notifyLogin()                                    
                                } else {
                                    self.notifyLoginFail(error: .unknownError(description: error?.localizedDescription ?? ""))
                                }
        }
    }
    
    func signIn(with email: String, password: String) {
        let credentials =  EmailAuthProvider.credential(withEmail: email, password: password)
        firebaseSignIn(with: credentials)
    }
    
    func sendResetPassword(for email: String, completion: ((AuthError?) -> ())?) {
        Auth.auth().sendPasswordReset(withEmail: email) { (error) in
            if let error = error {
                completion?(.unknownError(description: error.localizedDescription))
            } else {
                completion?(nil)
            }
        }
    }
    
    private func firebaseSignIn(with credentials: AuthCredential) {
        var oldAnonymous : User? = nil
        if Auth.auth().currentUser?.isAnonymous ?? false {
            oldAnonymous = Auth.auth().currentUser
        }
        
        let signInCallback : ((User?, Error?)->()) = { (user, error) in
            if let error = error {
                oldAnonymous?.delete(completion: nil)
                self.notifyLoginFail(error: .unknownError(description: error.localizedDescription))
            } else {
                self.notifyLogin()
            }
        }
        
        if let currentUser = Auth.auth().currentUser {
            currentUser.link(with: credentials) { (user, error) in
                if let _ = error {
                    Auth.auth().signIn(with: credentials, completion: signInCallback)
                } else {
                    self.notifyLogin()
                }
            }
        } else {
            Auth.auth().signIn(with: credentials, completion: signInCallback)
        }
    }
    
}

// MARK: Facebook

extension VisheoAuthorizationService {
    func loginWithFacebook(from vc: UIViewController?) {
        //NOTE: Consider getting top view controller in case if we receive nil if such case will be possible.
        //Currently crash in case of nil
        let viewController = vc!
        
        let login = FBSDKLoginManager()
        login.logIn(withReadPermissions: ["email", "public_profile"],
                    from:  viewController) { (result, error) in
                        if let error = error {
                            self.notifyLoginFail(error: .unknownError(description: error.localizedDescription))
                        } else {
                            if result?.isCancelled ?? true {
                                self.notifyLoginFail(error: .cancelled)
                                return
                            }
                            let credential = FacebookAuthProvider.credential(withAccessToken: FBSDKAccessToken.current().tokenString)
                            self.firebaseSignIn(with: credential)
                        }
        }
    }
}

// MARK: Google

extension VisheoAuthorizationService : GIDSignInDelegate, GIDSignInUIDelegate {
    func setupGoogleDependencies() {
        GIDSignIn.sharedInstance().clientID = FirebaseApp.app()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    func loginWithGoogle(from vc: UIViewController?) {
        //NOTE: Consider getting top view controller in case if we receive nil if such case will be possible.
        //Currently crash in case of nil
        let viewController = vc!
        presentationViewController = viewController
        GIDSignIn.sharedInstance().signIn()
    }
    
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        if let error = error {
            if (error as NSError).code == GIDSignInErrorCode.canceled.rawValue {
                self.notifyLoginFail(error: .cancelled)
            } else {
                self.notifyLoginFail(error: .unknownError(description: error.localizedDescription))
            }
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        
        
        firebaseSignIn(with :credential)
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        presentationViewController?.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        presentationViewController?.dismiss(animated: true, completion: nil)
    }
}
