//
//  InvitesService.swift
//  Visheo
//
//  Created by Ivan on 4/13/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation
import Firebase
import FirebaseDynamicLinks

enum linkParams : String {
    case invitedBy = "invitedBy"
}

protocol InvitesService {
    func registerFCMToken(withToken token: String, forUserId userId: String)
    func createInviteURLIfNeeded(withCompletion completion: @escaping (URL?) -> (Void))
    func handleDynamicLink(from dynamicLink: DynamicLink?) -> Bool
    func activateInvitation(forUserId userId: String, withPromo promo: String)
}

struct DynamicLinkParams {
    let googleAppId = "aj6fz"
    let bundleId = "com.visheo.visheo"
    let packageName = "com.visheo"
    let minimumAndroidVersion = 131
    let minimumIOSVersion = "1.0"
    let appStoreId = "1321534014"
}

class VisheoInvitesService : InvitesService {
    var userInfo: UserInfoProvider?
    var authService: AuthorizationService?
    var usersRef: DatabaseReference
    
    var invitedById: String?
    
    init(withAuthorizationService authService: AuthorizationService, userInfo: UserInfoProvider) {
        usersRef = Database.database().reference().child("users")
        self.authService = authService
        self.userInfo = userInfo
    }
    
    func registerFCMToken(withToken token: String, forUserId userId: String) {
        self.usersRef.child(userId).child("fcm_tokens").childByAutoId().setValue(token)
    }
    
    func createInviteURLIfNeeded(withCompletion completion: @escaping (URL?) -> (Void)) {
        let params = DynamicLinkParams()
        
        guard let uid = userInfo?.userId else { return }
        let link = URL(string: "https://visheo.com/?\(linkParams.invitedBy)=\(uid)")
        let referralLink = DynamicLinkComponents(link: link!, domain: "\(params.googleAppId).app.goo.gl")
        
        referralLink.iOSParameters = DynamicLinkIOSParameters(bundleID: params.bundleId)
        referralLink.iOSParameters?.minimumAppVersion = params.minimumIOSVersion
        referralLink.iOSParameters?.appStoreID = params.appStoreId
        
        referralLink.androidParameters = DynamicLinkAndroidParameters(packageName: params.packageName)
        referralLink.androidParameters?.minimumVersion = params.minimumAndroidVersion
        
        referralLink.shorten { (shortURL, warnings, error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            completion(shortURL)
        }
    }
    
    func handleDynamicLink(from dynamicLink: DynamicLink?) -> Bool {
        guard let dynamicLink = dynamicLink else { return false }
        guard let deepLink = dynamicLink.url else { return false }
        let queryItems = URLComponents(url: deepLink, resolvingAgainstBaseURL: true)?.queryItems
        invitedById = queryItems?.filter({(item) in item.name == linkParams.invitedBy.rawValue}).first?.value
        return true
    }
    
    func handleAuthorization() {
        let userId = userInfo?.userId
        if let userId = userId, let invitedBy = invitedById {
            activateInvitation(forUserId: userId, withPromo: invitedBy)
            invitedById = nil
        }
    }
    
    func activateInvitation(forUserId userId: String, withPromo promo: String) {
        let userRecord = Database.database().reference().child("users").child(userId)
        userRecord.child("referred_by").setValue(promo)
    }
    
}
