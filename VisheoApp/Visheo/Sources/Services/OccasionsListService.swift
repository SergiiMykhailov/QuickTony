//
//  OccasionsListService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/8/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase

extension Notification.Name {
    static let occasionsChanged = Notification.Name("occasionsChanged")
}

protocol OccasionsListService: class {
    var occasionRecords : [OccasionRecord] {get}
}

enum OccasionCategory {
    case holiday
    case occasion
}

protocol OccasionRecord {
    var name : String {get}
    var date : Date? {get}
    var priority : Int {get}
    var category : OccasionCategory {get}
    
    var previewCover: OccasionCover {get}
    var covers : [OccasionCover] {get}
}

protocol OccasionCover {
    var id : Int {get}
    var url : URL? {get}
    var previewUrl : URL? {get}
}

class VisheoOccasionsListService : OccasionsListService {
    var occasionRecords: [OccasionRecord] {
        return _occasionRecords
    }
    
    let occasionsRef : DatabaseReference
    let coversRef : DatabaseReference
    var _occasionRecords : [VisheoOccasionRecord] = []
    var occasionObservers : [Int : [Int: DatabaseHandle]] = [:]
    
    init() {
        occasionsRef = Database.database().reference().child("occasions")
        coversRef = Database.database().reference().child("covers")
        loadOccasions()
    }
    
    func loadOccasions() {
        occasionsRef.observe(.value) { (snapshot) in
            self.stopObservingCovers()
            guard let occasions = snapshot.value as? [Any] else {return}
            self._occasionRecords =  occasions.flatMap { $0 as? [String : Any] }
                                            .flatMap { VisheoOccasionRecord(dictionary: $0) }
            self.startObservingCovers()
        }
    }
    func startObservingCovers() {
        for (index, occasion) in self._occasionRecords.enumerated() {
            self.observeCovers(for: occasion, at: index)
        }
    }
    
    func stopObservingCovers() {
        for (index, _) in self._occasionRecords.enumerated() {
            if let occasionObservers = occasionObservers[index] {
                occasionObservers.forEach({ (key, value) in
                    coversRef.child("\(key)").removeObserver(withHandle: value)
                })
            }
        }
    }
    
    func didChange(at index: Int) {
        NotificationCenter.default.post(name: .occasionsChanged, object: self)
    }
    
    func observeCovers(for occasion: VisheoOccasionRecord, at index: Int) {
        
        var currentOccasionObservers : [Int:DatabaseHandle] = [:]
        
        for (coverIndex, cover) in occasion.covers.enumerated() {
            let coverObserverId = coversRef.child("\(cover.id)").observe(.value, with: { (snapshot) in
                occasion.cover(at: coverIndex)?.update(with: snapshot.value as? [String : Any])
                self.didChange(at: index)
            })
            currentOccasionObservers[coverIndex] = coverObserverId
        }
        
        occasionObservers[index] = currentOccasionObservers
    }
}

class VisheoOccasionRecord : OccasionRecord {
    var previewCover: OccasionCover
    var covers: [OccasionCover]
    let priority: Int
    let name : String
    let date : Date?
    let category : OccasionCategory
    
    fileprivate func cover(at index: Int) -> VisheoOccasionCover? {
        if index < covers.count {
            return covers[index] as? VisheoOccasionCover
        }
        return nil
    }
    
    init?(dictionary : [String : Any]) {
        name = dictionary["name"] as? String ?? ""
        
        covers = (dictionary["covers"] as? [Int] ?? []).map { VisheoOccasionCover(id: $0) }
        
        date = VisheoOccasionRecord.date(from: dictionary["date"] as? String)
        priority = dictionary["priority"] as? Int ?? Int.max
        if let previewId = dictionary["preview"] as? Int, previewId < covers.count {
            previewCover = covers[previewId]
        } else {
            return nil
        }
        
        if let stringCat = dictionary["category"] as? String {
            category = stringCat == "holiday" ? .holiday : .occasion
        } else {
            category = .occasion
        }
    }
    
    static func date(from string: String?) -> Date? {
        guard let dateString = string else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd'-'MM'-'yyyy"
        return formatter.date(from: dateString)
    }
}

class VisheoOccasionCover : OccasionCover {
    let id: Int
    var url: URL?
    var previewUrl: URL?
    init(id : Int) {
        self.id = id
    }
    
    func update(with dictionary : [String : Any]?) {
        guard let snapshot = dictionary else {return}
        
        url = URL(string: snapshot["url"] as? String ?? "")
        previewUrl = URL(string: snapshot["previewUrl"] as? String ?? "") ?? url
    }
}
