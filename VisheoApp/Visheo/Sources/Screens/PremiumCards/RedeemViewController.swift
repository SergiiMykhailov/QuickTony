//
//  RedeemViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/11/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class RedeemViewController: UIViewController, UITextFieldDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
        
        viewModel.showProgressCallback = {[weak self] in
            guard let `self` = self else {return}
            if $0 {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        viewModel.premiumUsageFailedHandler = {[weak self] in
            self?.handlePremiumCardUsageError()
        }
        
        if viewModel.showBackButton {
            navigationItem.leftBarButtonItems = [backItem]
        } else {
            navigationItem.leftBarButtonItems = [menuItem]
        }
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: RedeemViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: RedeemViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: Outlets
    
    @IBOutlet weak var backItem: UIBarButtonItem!
    @IBOutlet weak var menuItem: UIBarButtonItem!
    @IBOutlet weak var couponCodeField: UITextField!
    
    // MARK: Actions
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func redeemPressed(_ sender: Any) {
        viewModel.redeem(coupon: couponCodeField.text ?? "")
    }
    
    // MARK: Text field delegate
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        redeemPressed(self)
        return true
    }
    
    // MARK: Private
    
    private func handlePremiumCardUsageError() {
        let alertController = UIAlertController(title: NSLocalizedString("Oops…", comment: "error using premium card title"), message: NSLocalizedString("Something went wrong. Please check your Internet connection and try again.", comment: "something went wrong while suing premium card"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: "Try again button text"), style: .default, handler: { (action) in
            self.viewModel.retrySend()
        }))
        
        present(alertController, animated: true, completion: nil)
    }
}


extension RedeemViewController {
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
