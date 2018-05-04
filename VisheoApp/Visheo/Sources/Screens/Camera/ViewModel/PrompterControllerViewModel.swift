//
//  PrompterControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/30/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

extension Notification.Name {
    static let PrompterDidSwiped = Notification.Name("PrompterDidSwiped")
}

protocol PrompterViewModel: class {
    var pagesNumber: Int { get }
    var currentPage: Int { get set }
    var pageIndicatorText: String { get }
    
    var currentPageChanged: (()->())? { get set }
    
    func text(forIndex index: Int) -> String
}

final class PrompterControllerViewModel: PrompterViewModel {

    // MARK: - Private properties -
    private(set) weak var router: PrompterRouter?
    private var words: [WordIdea]
    private var appStateService: AppStateService
    // MARK: - Lifecycle -

    init(router: PrompterRouter, words: [WordIdea], appStateService: AppStateService) {
        self.router = router
        self.currentPage = 0
        self.words = words
        self.appStateService = appStateService
    }

    var currentPageChanged: (()->())?
    
    var pagesNumber: Int {
        return words.count
    }
    
    var currentPage: Int {
        didSet {
            if (currentPage != oldValue && appStateService.shouldShowSwipeOnboarding) {
                appStateService.swipeOnboarding(wasSeen: true)
                NotificationCenter.default.post(name: Notification.Name.PrompterDidSwiped, object: self)
            }
            
            currentPageChanged?()
        }
    }
    
    var pageIndicatorText: String {
        return "\(currentPage + 1) / \(pagesNumber)"
    }
    
    func text(forIndex index: Int) -> String {
        return words[index].text ?? ""
    }
    
    // MARK: - Actions -
}
