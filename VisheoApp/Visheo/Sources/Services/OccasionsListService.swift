//
//  OccasionsListService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/8/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase

protocol OccasionsListService: class {
    func occasionsRecords() -> [OccasionRecord]
    var didChangeRecords : (()->())? {get set}
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
    var previewCoverUrl : URL? {get}
}

class VisheoOccasionsListService : OccasionsListService {
    var didChangeRecords: (() -> ())?
    
    func occasionsRecords() -> [OccasionRecord] {
        return occasionRecords
    }
    
    let occasionsRef : DatabaseReference
    let coversRef : DatabaseReference
    var occasionRecords : [VisheoOccasionRecord] = []
    var occasionObservers : [Int : UInt] = [:]
    
    init() {
        occasionsRef = Database.database().reference().child("occasions")
        coversRef = Database.database().reference().child("covers")
        loadOccasions()
    }
    
    func loadOccasions() {
        occasionsRef.observeSingleEvent(of: .value) { (snapshot) in
            guard let occasions = snapshot.value as? [Any] else {return}
            self.occasionRecords =  occasions.flatMap { $0 as? [String : Any] }
                                            .flatMap { VisheoOccasionRecord(dictionary: $0) }
            
            for (index, occasion) in self.occasionRecords.enumerated() {
                self.observe(occasion: occasion, at: index)
            }
        }
    }
    
    func didChange(at index: Int) {
        didChangeRecords?()
    }
    
    func observe(occasion: VisheoOccasionRecord, at index: Int) {
        if let coverId = occasion.previewCoverId {
            let observerId = coversRef.child("\(coverId)").observe(.value, with: { (snapshot) in
                
                if let urlString = (snapshot.value as? [String : Any])?["url"] as? String {
                    let occasion = self.occasionRecords[index]
                    occasion.previewCoverUrl = URL(string: urlString)
                    self.didChange(at: index)
                }
            })
            occasionObservers[index] = observerId
        }
    }
}

class VisheoOccasionRecord : OccasionRecord {
    let priority: Int
    let covers : [Int]
    let name : String
    let date : Date?
    let category : OccasionCategory
    
    var previewCoverUrl : URL?
    let previewCoverId : Int?
    
    init?(dictionary : [String : Any]) {
        name = dictionary["name"] as? String ?? ""
        covers = dictionary["covers"] as? [Int] ?? []
        date = VisheoOccasionRecord.date(from: dictionary["date"] as? String)
        priority = dictionary["priority"] as? Int ?? Int.max
        if let previewId = dictionary["preview"] as? Int, previewId < covers.count {
            previewCoverId = covers[previewId]
        } else {
            previewCoverId = nil
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
