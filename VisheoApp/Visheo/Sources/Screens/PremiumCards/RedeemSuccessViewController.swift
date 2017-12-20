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
		
		viewModel.premiumUsageFailedHandler = {[weak self] in
			self?.handlePremiumCardUsageError()
		}
		
		continueButton.setTitle(viewModel.continueDescription, for: .normal);
		title = viewModel.titleDescription.uppercased();
		
		if viewModel.showBackButton {
			navigationItem.leftBarButtonItems = [backItem]
		} else {
			navigationItem.leftBarButtonItems = [menuItem]
		}
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: RedeemSuccessViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: RedeemSuccessViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
	
	
	private func handlePremiumCardUsageError() {
		let alertController = UIAlertController(title: NSLocalizedString("Oops…", comment: "error using premium card title"), message: NSLocalizedString("Something went wrong. Please check your Internet connection and try again.", comment: "something went wrong while suing premium card"), preferredStyle: .alert)
		
		alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
		alertController.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: "Try again button text"), style: .default, handler: { (action) in
			self.viewModel.retryPremiumUse()
		}))
		
		present(alertController, animated: true, completion: nil)
	}
    
    // MARK: Outlets
    
    @IBOutlet weak var couponAddedDescriptionLabel: UILabel!
	@IBOutlet weak var backItem: UIBarButtonItem!
	@IBOutlet weak var menuItem: UIBarButtonItem!
	@IBOutlet weak var continueButton: UIButton!
	
    // MARK: Actions
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
	
	@IBAction func backPressed(_ sender: Any) {
		navigationController?.popViewController(animated: true);
	}
	
    @IBAction func createPressed(_ sender: Any) {
        viewModel.createOrContinue()
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
