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

enum OccasionCategory: String {
    case holiday
    case occasion
	case featured
}

protocol OccasionRecord {
    var name : String {get}
    var date : Date? {get}
    var priority : Int {get}
    var category : OccasionCategory {get}
    
    var previewCover: OccasionCover {get}
    var covers : [OccasionCover] {get}
	var soundtracks: [OccasionSoundtrack] { get }
	var words: [WordIdea] { get }
}

protocol OccasionCover {
    var id : Int {get}
    var url : URL? {get}
    var previewUrl : URL? {get}
}

protocol OccasionSoundtrack {
	var id: Int { get }
	var url: URL? { get }
	var title: String? { get }
	var license: String? { get }
}

protocol WordIdea {
	var id: Int { get }
	var text: String? { get }
}


class VisheoOccasionsListService : OccasionsListService {
    var occasionRecords: [OccasionRecord] {
        return _occasionRecords
    }
	
	private enum ObserverType {
		case covers
		case soundtracks
		case words
		
		static let allTypes: [ObserverType] = [.covers, .soundtracks, .words]
	}
    
    let occasionsRef : DatabaseReference
    let coversRef : DatabaseReference
	let soundtracksRef: DatabaseReference
	let wordsRef: DatabaseReference
    var _occasionRecords : [VisheoOccasionRecord] = []
	private var occasionObservers : [Int : [ ObserverType : [Int: DatabaseHandle]]] = [:]
    
    init() {
        occasionsRef = Database.database().reference().child("occasions")
        coversRef = Database.database().reference().child("covers")
		soundtracksRef = Database.database().reference().child("music");
		wordsRef = Database.database().reference().child("words");
		
        loadOccasions()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.authStateChanged, object: nil, queue: OperationQueue.main) { (notitication) in
            self.loadOccasions()
        }
    }
    
    func loadOccasions() {
        occasionsRef.observe(.value) { (snapshot) in
            self.stopObserving()
            guard let occasions = snapshot.value as? [Any] else {return}
            self._occasionRecords =  occasions.flatMap { $0 as? [String : Any] }
                                            .flatMap { VisheoOccasionRecord(dictionary: $0) }
            self.startObserving()
        }
    }
	
	private func startObserving(for types: [ObserverType] = ObserverType.allTypes) {
        for (index, occasion) in self._occasionRecords.enumerated() {
			self.observe(types: types, for: occasion, at: index);
        }
    }
	
	private func databaseRef(for type: ObserverType) -> DatabaseReference {
		switch type {
			case .covers:
				return coversRef;
			case .soundtracks:
				return soundtracksRef;
			case .words:
				return wordsRef;
		}
	}
    
	private func stopObserving(for types: [ObserverType] = ObserverType.allTypes)
	{
        for (index, _) in self._occasionRecords.enumerated() {
			for type in types {
				let observers = occasionObservers[index];
				let dbRef = databaseRef(for: type);
				
				if let observersForType = observers?[type] {
					observersForType.forEach { (key, value) in
						dbRef.child("\(key)").removeObserver(withHandle: value);
					}
				}
			}
        }
    }
    
    func didChange(at index: Int) {
        NotificationCenter.default.post(name: .occasionsChanged, object: self)
    }
	
	
	private func observe(types: [ObserverType] = ObserverType.allTypes, for occasion: VisheoOccasionRecord, at index: Int) {
		var observers: [ ObserverType : [Int: DatabaseHandle] ] = [:]
		
		for type in types {
			var currentOccasionObservers : [Int:DatabaseHandle];
			switch type {
				case .covers:
					currentOccasionObservers = observeCovers(for: occasion, at: index);
				case .soundtracks:
					currentOccasionObservers = observeSoundtracks(for: occasion, at: index);
				case .words:
					currentOccasionObservers = observeWords(for: occasion, at: index);
			}
			observers[type] = currentOccasionObservers
		}
        occasionObservers[index] = observers
    }
	
	
	private func observeCovers(for occasion: VisheoOccasionRecord, at index: Int) -> [Int: DatabaseHandle] {
		var currentOccasionObservers : [Int:DatabaseHandle] = [:]
		
		for (coverIndex, cover) in occasion.covers.enumerated() {
			let coverObserverId = coversRef.child("\(cover.id)").observe(.value, with: { (snapshot) in
				occasion.cover(at: coverIndex)?.update(with: snapshot.value as? [String : Any])
				self.didChange(at: index)
			})
			currentOccasionObservers[coverIndex] = coverObserverId
		}
		
		return currentOccasionObservers;
	}
	
	
	private func observeSoundtracks(for occasion: VisheoOccasionRecord, at index: Int) -> [Int: DatabaseHandle] {
		var currentOccasionObservers : [Int:DatabaseHandle] = [:]
		
		for (soundtrackIndex, soundtrack) in occasion.soundtracks.enumerated() {
			let soundtrackObserverId = soundtracksRef.child("\(soundtrack.id)").observe(.value, with: { (snapshot) in
				occasion.soundtrack(at: soundtrackIndex)?.update(with: snapshot.value as? [String : Any])
				self.didChange(at: index)
			})
			currentOccasionObservers[soundtrackIndex] = soundtrackObserverId
		}
		
		return currentOccasionObservers;
	}
	
	private func observeWords(for occasion: VisheoOccasionRecord, at index: Int) -> [Int: DatabaseHandle] {
		var currentOccasionObservers : [Int:DatabaseHandle] = [:]
		
		for (index, word) in occasion.words.enumerated() {
			let wordObserverId = wordsRef.child("\(word.id)").observe(.value, with: { (snapshot) in
				occasion.word(at: index)?.update(with: snapshot.value as? [String : Any])
				self.didChange(at: index)
			})
			currentOccasionObservers[index] = wordObserverId
		}
		
		return currentOccasionObservers;
	}
}

class VisheoOccasionRecord : OccasionRecord {
    var previewCover: OccasionCover
    var covers: [OccasionCover]
    let priority: Int
    let name : String
    let date : Date?
    let category : OccasionCategory
	let soundtracks: [OccasionSoundtrack]
	let words: [WordIdea]
    
    fileprivate func cover(at index: Int) -> VisheoOccasionCover? {
        if index < covers.count {
            return covers[index] as? VisheoOccasionCover
        }
        return nil
    }
	
	fileprivate func soundtrack(at index: Int) -> VisheoOccasionSoundtrack? {
		if index < soundtracks.count {
			return soundtracks[index] as? VisheoOccasionSoundtrack
		}
		return nil
	}
	
	fileprivate func word(at index: Int) -> VisheoWordIdea? {
		if index < words.count {
			return words[index] as? VisheoWordIdea
		}
		return nil
	}
    
    init?(dictionary : [String : Any]) {
        name = dictionary["name"] as? String ?? ""
        
        covers = (dictionary["covers"] as? [Int?] ?? []).flatMap{$0}
                                                        .map { VisheoOccasionCover(id: $0) }
		soundtracks = (dictionary["music"] as? [Int?] ?? []).flatMap{$0}
                                                            .map { VisheoOccasionSoundtrack(id: $0) }
		
		words = (dictionary["words"] as? [Int?] ?? []).flatMap{$0}
															.map { VisheoWordIdea(id: $0) }
		
        date = VisheoOccasionRecord.date(from: dictionary["date"] as? String)
        priority = dictionary["priority"] as? Int ?? Int.max
        if let previewId = dictionary["preview"] as? Int, previewId < covers.count {
            previewCover = covers[previewId]
        } else {
            return nil
        }
        
		if let stringCat = dictionary["category"] as? String, let cat = OccasionCategory(rawValue: stringCat) {
			category = cat;
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

class VisheoOccasionSoundtrack: OccasionSoundtrack {
	let id: Int
	var url: URL?
	var title: String?
	var license: String?
	
	init(id: Int) {
		self.id = id;
	}
	
	func update(with dictionary : [String : Any]?) {
		guard let snapshot = dictionary else {return}
		
		url = (snapshot["url"] as? String).flatMap{ URL(string: $0) }
		title =	snapshot["name"] as? String;
		license = snapshot["license"] as? String;
	}
}

class VisheoWordIdea: WordIdea {
	let id: Int;
	var text: String?;
	
	init(id: Int) {
		self.id = id;
	}
	
	func update(with dictionary : [String : Any]?) {
		guard let snapshot = dictionary else {return}
		text = snapshot["text"] as? String;
	}
}
