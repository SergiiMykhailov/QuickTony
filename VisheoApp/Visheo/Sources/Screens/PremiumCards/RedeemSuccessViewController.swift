//
//  RedeemSuccessViewController.swift
//  
//
//  Created by Petro Kolesnikov on 12/11/17.
//

import UIKit

class RedeemSuccessViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        couponAddedDescriptionLabel.text = viewModel.redeemedDescription
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: RedeemSuccessViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: RedeemSuccessViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    // MARK: Outlets
    
    @IBOutlet weak var couponAddedDescriptionLabel: UILabel!
        
    // MARK: Actions
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func createPressed(_ sender: Any) {
        viewModel.showCreate()
    }
}


extension RedeemSuccessViewController {
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
