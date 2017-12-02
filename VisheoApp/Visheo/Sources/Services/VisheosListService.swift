//
//  VisheosListService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Firebase

extension Notification.Name {
    static let visheosChanged = Notification.Name("visheosChanged")
}

protocol VisheosListService: class {
    var visheosRecords : [VisheoRecord] {get}
}

protocol VisheoRecord {
    var id: String {get}
    
    var videoUrl: URL? {get}
    var coverUrl: URL? {get}
    var name: String? {get}
    var visheoLink : String? {get}
    var timestamp : Double? {get}
}

class VisheoBoxService : VisheosListService {
    var visheosRecords: [VisheoRecord] = []

    var userVisheosRef : DatabaseReference?
    let visheosRef : DatabaseReference
    var occasionObservers : [String : DatabaseHandle] = [:]
    private let userProvider : UserInfoProvider
    
    init(userInfoProvider : UserInfoProvider) {
        visheosRef = Database.database().reference().child("cards")
        self.userProvider = userInfoProvider
        startObserving(user: userProvider.userId)
        
        NotificationCenter.default.addObserver(forName: Notification.Name.authStateChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.startObserving(user: self?.userProvider.userId)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func startObserving(user userId: String?) {
        visheosRecords.removeAll()
        if let id = userId {
            userVisheosRef = Database.database().reference().child("users/\(id)/cards")
            loadVisheos()
        }
    }
    
    func loadVisheos() {
        userVisheosRef?.observe(.value) { (snapshot) in
            self.stopObservingVisheos()
            self.visheosRecords.removeAll()
            guard let visheos = snapshot.value as? [String: Any] else {return}
            
            self.visheosRecords =  visheos.map { $0.key }
                .flatMap { VisheoCardRecord(id: $0) }
            self.startObservingVisheos()
        }
    }
    func startObservingVisheos() {
        for visheo in self.visheosRecords {
            
            let visheoObserverId = visheosRef.child("\(visheo.id)").observe(.value, with: { (snapshot) in
                (visheo as? VisheoCardRecord)?.update(with: snapshot.value as? [String : Any])
                self.didChange(at: visheo.id)
            })
            
            occasionObservers[visheo.id] = visheoObserverId
        }
    }
    
    func stopObservingVisheos() {
        occasionObservers.forEach { (key, value) in
            visheosRef.child("\(key)").removeObserver(withHandle: value)
        }
    }
    
    func didChange(at id: String) {
        NotificationCenter.default.post(name: .visheosChanged, object: self)
    }
}

class VisheoCardRecord : VisheoRecord {
    let id: String
    
    var videoUrl: URL?
    var coverUrl: URL?
    var name: String?
    var visheoLink: String?
    var timestamp: Double?
    
    init(id : String) {
        self.id = id
    }
    
    func update(with dictionary : [String : Any]?) {
        guard let snapshot = dictionary else {return}
        
        videoUrl   = URL(string: snapshot["downloadUrl"] as? String ?? "")
        coverUrl   = URL(string: snapshot["coverPreviewUrl"] as? String ?? "")
        name       = snapshot["occasionName"] as? String
        visheoLink = snapshot["visheoUrl"] as? String
        timestamp  = snapshot["timestamp"] as? Double
    }
}
