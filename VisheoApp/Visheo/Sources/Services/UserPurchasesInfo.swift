//
//  UserPurchasesInfo.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol UserPurchasesInfo {
    var premiumCardsNumber : Int {get}
}

struct DummyUserPurchasesInfo : UserPurchasesInfo {
    let premiumCardsNumber: Int
}
