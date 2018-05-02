//
//  PrompterViewController.swift
//  Visheo
//
//  Created by Ivan on 4/30/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

final class PrompterViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: PrompterViewModel!
    private(set) var router: FlowRouter!
    private var collectionViewMediator: PrompterWordsCollectionMediator?
    
    @IBOutlet weak var wordsCollectionView: UICollectionView!
    @IBOutlet weak var pageIndicateLabel: UILabel!

    // MARK: - Configuration -

    func configure(viewModel: PrompterViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
        
        viewModel.currentPageChanged = { [weak self] in
            self?.loadDataFromViewModel()
        }
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        collectionViewMediator = PrompterWordsCollectionMediator(viewModel: viewModel, wordsCollection: wordsCollectionView)
        loadDataFromViewModel()
    }
    
    func loadDataFromViewModel() {
        pageIndicateLabel.text = viewModel.pageIndicatorText
    }
    
    // MARK: - Actions -
    
    @IBAction func clearAllButtonPressed() {
        viewModel.clearAllPressed()
    }
}

// MARK: - Router -
extension PrompterViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}
