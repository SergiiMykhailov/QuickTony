//
//  InvitesService.swift
//  Visheo
//
//  Created by Ivan on 4/13/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation

protocol InvitesService {
    func registerUUID(withId id: String, forUserId userId: String)
    func createInviteURLIfNeeded(forUserId userId: String) -> URL
    func getPromo(fromURL url: URL) -> String
    func activateInvitation(forUserId userId: String, withPromo promo: String)
}

class VisheoInvitesService : InvitesService {
    func registerUUID(withId id: String, forUserId userId: String) {
        
    }
    
    func createInviteURLIfNeeded(forUserId userId: String) -> URL {
        return URL(fileURLWithPath: "")
    }
    
    func getPromo(fromURL url: URL) -> String {
        return ""
    }
    
    func activateInvitation(forUserId userId: String, withPromo promo: String) {
        
    }
    
}
