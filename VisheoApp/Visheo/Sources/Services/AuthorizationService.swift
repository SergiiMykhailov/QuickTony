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
    
    func loginWithFacebook(from vc: UIViewController?)
    func loginWithGoogle(from vc: UIViewController?)
}

extension Notification.Name {
    static let userLoggedIn = Notification.Name("userLoggedIn")
    static let userLoginFailed = Notification.Name("userLoginFailed")
}

extension Notification {
    enum Keys {
        static let error = "Error"
    }
}

enum LoginError: Error {
    case cancelled
    case unknownError(description : String)
}

class VisheoAuthorizationService : NSObject, AuthorizationService {
    var isAuthorized: Bool = false
    weak var presentationViewController : UIViewController?
    
    override init() {
        super.init()
        setupGoogleDependencies()
    }
    
    func notifyLogin() {
        NotificationCenter.default.post(name: .userLoggedIn, object: self)
    }
    
    func notifyLoginFail(error: LoginError) {
        NotificationCenter.default.post(name: .userLoginFailed, object: self, userInfo: [Notification.Keys.error : error])
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
                            Auth.auth().signIn(with: credential) { (user, error) in
                                if let error = error {
                                    self.notifyLoginFail(error: .unknownError(description: error.localizedDescription))
                                } else {
                                    self.notifyLogin()
                                }
                            }
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
        
        Auth.auth().signIn(with: credential) { (user, error) in
            if let error = error {
                self.notifyLoginFail(error: .unknownError(description: error.localizedDescription))
            } else {
                self.notifyLogin()
            }
        }
    }
    
    func sign(_ signIn: GIDSignIn!, present viewController: UIViewController!) {
        presentationViewController?.present(viewController, animated: true, completion: nil)
    }
    
    func sign(_ signIn: GIDSignIn!, dismiss viewController: UIViewController!) {
        presentationViewController?.dismiss(animated: true, completion: nil)
    }
}
