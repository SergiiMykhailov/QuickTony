//
//  VisheoBoxViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol VisheoBoxViewModel : class {
    func showMenu()
    
    var didChangeCallback: (()->())? {get set}
    
    var visheosCount : Int {get}
    func visheo(at index: Int) -> VisheoCellViewModel
}

class VisheoListViewModel : VisheoBoxViewModel {
    var didChangeCallback: (() -> ())?
    
    weak var router: VisheoBoxRouter?
    let visheosList : VisheosListService
    
    init(visheosList: VisheosListService) {
        self.visheosList = visheosList
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheosChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.didChangeCallback?()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var visheosCount: Int {
        return visheos.count
    }
    
    func visheo(at index: Int) -> VisheoCellViewModel {
        let record = visheos[index]
        return VisheoCellViewModel(coverUrl: record.coverUrl, visheoTitle: record.name)
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    var visheos : [VisheoRecord] {
        return visheosList.visheosRecords.filter {_ in
            return true
            }.sorted(by: { (left, right) -> Bool in
                switch (left.timestamp, right.timestamp) {
                case (nil, nil):
                    return left.id.compare(right.id, options: .caseInsensitive) == .orderedAscending
                case (nil, _?):
                    return false
                case ( _?, nil):
                    return true
                case (let leftTimestamp?, let rightTimestamp?):
                    return leftTimestamp > rightTimestamp
                }
            })
        
    }
}
