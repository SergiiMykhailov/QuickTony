//
//  PrompterControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/30/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol PrompterViewModel: class {
    var pagesNumber: Int { get }
    var currentPage: Int { get set }
    var pageIndicatorText: String { get }
    
    var currentPageChanged: (()->())? { get set }
    
    func clearAllPressed()
    func text(forIndex index: Int) -> String
}

final class PrompterControllerViewModel: PrompterViewModel {

    // MARK: - Private properties -
    private(set) weak var router: PrompterRouter?
    private var words: [WordIdea]
    private var clearAllAction: ()->()
    // MARK: - Lifecycle -

    init(router: PrompterRouter, words: [WordIdea], clearAllAction: @escaping ()->()) {
        self.router = router
        self.currentPage = 0
        self.words = words
        self.clearAllAction = clearAllAction
    }

    var currentPageChanged: (()->())?
    
    var pagesNumber: Int {
        return words.count
    }
    
    var currentPage: Int {
        didSet {
            currentPageChanged?()
        }
    }
    
    func clearAllPressed() {
        clearAllAction()
    }
    
    var pageIndicatorText: String {
        return "\(currentPage + 1) / \(pagesNumber)"
    }
    
    func text(forIndex index: Int) -> String {
        return words[index].text ?? ""
    }
    
    // MARK: - Actions -
}
