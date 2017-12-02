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
    var didChangeAt: ((Int)->())? {get set}
    
    var visheosCount : Int {get}
    func visheo(at index: Int) -> VisheoCellViewModel
    func select(visheo at: Int)
}

class VisheoListViewModel : VisheoBoxViewModel {
    var didChangeAt: ((Int) -> ())?
    var didChangeCallback: (() -> ())?
    
    weak var router: VisheoBoxRouter?
    private let visheosList : VisheosListService
    private let creationService : CreationService
    
    init(visheosList: VisheosListService, creationService : CreationService) {
        self.visheosList = visheosList
        self.creationService = creationService
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheosChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            self?.didChangeCallback?()
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoUploadingProgress, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String else {return}
            strongSelf.update(with: visheoId)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationSuccess, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String else {return}
            strongSelf.update(with: visheoId)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    var visheosCount: Int {
        return visheos.count
    }
    
    func visheo(at index: Int) -> VisheoCellViewModel {
        return cell(from: visheos[index])
    }
    
    func showMenu() {
        router?.showMenu()
    }
    
    func select(visheo at: Int)  {
        let record = visheos[at]
        if !creationService.isIncomplete(visheoId: record.id) {
            router?.show(visheo: record)
        }
    }
    
    // MARK: Private
    
    private func update(with id: String) {
        let index = visheos.index {
            $0.id == id
        }
        if let index = index {
            didChangeAt?(index)
        }
    }
    
    private var visheos : [VisheoRecord] {
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
    
    private func cell(from record: VisheoRecord) -> VisheoCellViewModel {
        let isUploading = creationService.isIncomplete(visheoId: record.id)
        let progress = creationService.uploadProgress(for: record.id) ?? 0.0
        
        return VisheoCellViewModel(coverUrl: record.coverUrl,
                                   visheoTitle: record.name,
                                   isUploading: isUploading,
                                   uploadProgress : progress)
    }
}
