//
//  OccasionGroupsService.swift
//  Visheo
//
//  Created by Ivan on 3/23/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import Foundation
import Firebase

extension Notification.Name {
    static let occasionGroupsChanged = Notification.Name("occasionGrpoupsChanged")
}

protocol OccasionGroupsListService: class {
    var occasionGroups : [OccasionGroup] {get}
}

enum OccasionGroupType: String {
    case standard
    case featured
}

protocol OccasionGroup {
    var title : String {get}
    var priority : Int {get}
    var type : OccasionGroupType {get}
    var occasions: [OccasionRecord] {get}
    var subTitle : String? {get}
    
    func update(withOccasionList occasionList: [OccasionRecord])
}

class VisheoOccasionGroupsListService : OccasionGroupsListService {
    var occasionGroups: [OccasionGroup] {
        return _occasionGroups
    }
    
    let occasionGroupsRef : DatabaseReference
    private var _occasionGroups : [OccasionGroup] = []
    private let _occasionListService : OccasionsListService
    
    init(occasionList: OccasionsListService) {
        _occasionListService = occasionList
        occasionGroupsRef = Database.database().reference().child("occasionGroups")
        
        loadOccasionGroups()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.authStateChanged, object: nil, queue: OperationQueue.main) { (notitication) in
            self.loadOccasionGroups()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.occasionsChanged, object: nil, queue: OperationQueue.main) { (notitication) in
            self.updateOccasionGroups()
        }
    }
    
    func loadOccasionGroups() {
        occasionGroupsRef.removeAllObservers()
        occasionGroupsRef.observe(.value) { (snapshot) in
            guard let occasionGroups = snapshot.value as? [String : Any] else {return}
            self._occasionGroups = occasionGroups.flatMap { $1 as? [String : Any] }
                .flatMap { VisheoOccasionGroup(dictionary: $0, occasionList: self._occasionListService.occasionRecords) }
            self.didChange()
        }
    }
    
    func updateOccasionGroups() {
        _occasionGroups.forEach {
            $0.update(withOccasionList: self._occasionListService.occasionRecords)
        }
        didChange()
    }
    
    let bgtasker = BackgroundTasker()
    
    func didChange() {
        bgtasker.mapOperation(withDelay: 10000) {
            print("call notification center")
            NotificationCenter.default.post(name: .occasionGroupsChanged, object: self)
        }
    }

}

class VisheoOccasionGroup : OccasionGroup {
    var title : String
    var priority : Int
    var type: OccasionGroupType
    var subTitle : String?
    
    private let _occasionIds : [Int]
    
    var occasions: [OccasionRecord] = []
    
    init?(dictionary : [String : Any], occasionList: [OccasionRecord]) {
        guard let stringGroupType = dictionary["groupType"] as? String,
              let grp = OccasionGroupType(rawValue: stringGroupType)
              else { return nil }
        
        title = dictionary["title"] as? String ?? ""
        subTitle = dictionary["subTitle"] as? String
        priority = dictionary["priority"] as? Int ?? Int.max
        _occasionIds = (dictionary["occasionIds"] as? [Int?] ?? []).flatMap{$0}
        type = grp
        
        update(withOccasionList: occasionList)
        }
    
    func update(withOccasionList occasionList: [OccasionRecord]) {
        occasions = _occasionIds.flatMap{ id in occasionList.first { $0.id == id } }
            .filter {
                if let group = $0 as? VisheoOccasionRecord {
                    return group.visible
                }
                return false
        }
    }
}
