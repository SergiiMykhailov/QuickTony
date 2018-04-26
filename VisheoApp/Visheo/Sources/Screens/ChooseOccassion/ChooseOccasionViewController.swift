//
//  ChooseOccasionViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class ChooseOccasionViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableViewMediator = OccasionGroupsTableMediator(withViewModel: viewModel, tableView: tableView)
        
        viewModel.didChangeCallback = {[weak self] in
            self?.tableView.reloadData()
        }
        
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: ChooseOccasionViewModel!
    private(set) var router: FlowRouter!
    private var tableViewMediator: OccasionGroupsTableMediator?
    
    func configure(viewModel: ChooseOccasionViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated);
		viewModel.showReviewChoiceIfNeeded()
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
