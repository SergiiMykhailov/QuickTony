//
//  ChooseOccasionViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class ChooseOccasionViewController: UIViewController {
    @IBOutlet weak var holidaysCollection: UICollectionView!
    @IBOutlet weak var occasionsCollection: UICollectionView!
    
    var holidaysCollectionMediator : HolidaysCollectionMediator?
    var occasionsCollectionMediator : OccassionsCollectionMediator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        holidaysCollectionMediator = HolidaysCollectionMediator(viewModel: viewModel,
                                                                holidaysCollection: holidaysCollection,
                                                                containerWidth: self.view.frame.width)
        
        occasionsCollectionMediator = OccassionsCollectionMediator(viewModel: viewModel,
                                                                   occasionsCollection: occasionsCollection)
        
        viewModel.didChangeCallback = {[weak self] in
            self?.holidaysCollectionMediator?.reloadData()
            self?.occasionsCollection.reloadData()
        }
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: ChooseOccasionViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: ChooseOccasionViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
}

extension ChooseOccasionViewController {
    //MARK: - Routing
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        router.prepare(for: segue, sender: sender)
    }
}
