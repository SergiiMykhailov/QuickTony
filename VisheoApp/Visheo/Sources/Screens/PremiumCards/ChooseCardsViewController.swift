//
//  ChooseCardViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class ChooseCardsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        if let couponAttributed = coupoButton.currentAttributedTitle?.mutableCopy() as? NSMutableAttributedString {
            couponAttributed.addAttributes([NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue], range: NSRange(location: 0, length: couponAttributed.length))
            coupoButton.setAttributedTitle(couponAttributed, for: .normal)
        }
        
        buyFifteenButton.titleLabel?.adjustsFontSizeToFitWidth = true
        buyFiveButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        viewModel.didChange = {[weak self] in
            self?.udpateFromVM()
        }
        
        viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
        
        viewModel.successAlertHandler = {[weak self] in
            self?.showSuccessAlertWithText(text: $0)
        }
        
        viewModel.customAlertHandler = {[weak self] in
            self?.showAlert(with: $0, text: $1)
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
            navigationItem.leftBarButtonItems = [backBarItem]
        } else {
            navigationItem.leftBarButtonItems = [menuBarItem]
        }
    }
    
    func udpateFromVM() {
        buyFiveButton.isHidden = viewModel.smallBundleButtonHidden
        buyFifteenButton.isHidden = viewModel.bigBundleButtonHidden
        
        buyFiveButton.setTitle(viewModel.smallBundleButtonText, for: .normal)
        buyFifteenButton.setTitle(viewModel.bigBundleButtonText, for: .normal)
        
        let hasCards = viewModel.premiumCardsNumber > 0
        noPremCardslabel.isHidden = hasCards
        haspremiumCardsContainer.isHidden = !hasCards
        premiumCardsLabel.text = "\(viewModel.premiumCardsNumber)"
    }
    
    private func handlePremiumCardUsageError() {
        let alertController = UIAlertController(title: NSLocalizedString("Oops…", comment: "error using premium card title"), message: NSLocalizedString("Something went wrong. Please check your Internet connection and try again.", comment: "something went wrong while suing premium card"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Try Again", comment: "Try again button text"), style: .default, handler: { (action) in
            self.viewModel.retryPremiumUse()
        }))
        
        present(alertController, animated: true, completion: nil)
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: ChooseCardsViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: ChooseCardsViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: Outlets
    
    @IBOutlet weak var buyFiveButton: UIButton!
    @IBOutlet weak var buyFifteenButton: UIButton!
    @IBOutlet weak var coupoButton: UIButton!
    
    @IBOutlet weak var haspremiumCardsContainer: UIView!
    @IBOutlet weak var premiumCardsLabel: UILabel!
    @IBOutlet weak var noPremCardslabel: UILabel!
    @IBOutlet weak var menuBarItem: UIBarButtonItem!
    @IBOutlet weak var backBarItem: UIBarButtonItem!
    
    // MARK: Actions
    @IBAction func sendFreePressed(_ sender: Any) {
        viewModel.sendRegular()
    }
    
    @IBAction func buySmallPressed(_ sender: Any) {
        viewModel.buySmallBundle()
    }
    
    @IBAction func buyBigPressed(_ sender: Any) {
        viewModel.buyBigBundle()
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension ChooseCardsViewController {
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
