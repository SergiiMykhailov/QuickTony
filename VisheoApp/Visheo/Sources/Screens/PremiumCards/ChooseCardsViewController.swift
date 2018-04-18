//
//  ChooseCardViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/6/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD
import SnapKit

class ChooseCardsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        buyFifteenButton.titleLabel?.adjustsFontSizeToFitWidth = true
        buyFiveButton.titleLabel?.adjustsFontSizeToFitWidth = true
        subcribeButton.titleLabel?.adjustsFontSizeToFitWidth = true
        
        if let couponAttributed = couponButton.currentAttributedTitle?.mutableCopy() as? NSMutableAttributedString {
            couponAttributed.addAttributes([NSAttributedStringKey.underlineStyle: NSUnderlineStyle.styleSingle.rawValue], range: NSRange(location: 0, length: couponAttributed.length))
            couponButton.setAttributedTitle(couponAttributed, for: .normal)
        }
        
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
        
        viewModel?.confirmFreeSendHandler = { [weak self] in
            self?.confirmFreeSending()
        }
        
        if viewModel.showBackButton {
            navigationItem.leftBarButtonItems = [backBarItem]
        } else {
            navigationItem.leftBarButtonItems = [menuBarItem]
        }
		
		udpateFromVM()
    }
    
    func udpateFromVM() {
        buyFiveButton.isHidden = viewModel.smallBundleButtonHidden
        buyFifteenButton.isHidden = viewModel.bigBundleButtonHidden
        
        if (!viewModel.smallBundleButtonHidden){
            smallPackageIndicator?.removeFromSuperview()
        }
        if (!viewModel.bigBundleButtonHidden){
            bigPackageIndicator?.removeFromSuperview()
        }
        
        buyFiveButton.setTitle(viewModel.smallBundleButtonText, for: .normal)
        buyFifteenButton.setTitle(viewModel.bigBundleButtonText, for: .normal)
        subcribeButton.setTitle(viewModel.subscribeButtonText, for: .normal)
        
        premiumCardsLabel.text = "\(viewModel.premiumCardsNumber)"
        untilDateLabel.text = "\(viewModel.untilDateText)"
		
		freeCardsSection.isHidden = !viewModel.showFreeSection
        premiumCardsSection.isHidden = viewModel.showSubscribedSection
        subscribeSection.isHidden = viewModel.subscribeSectionHidden
        couponSection.isHidden = !viewModel.showCouponSection
        subscribedSection.isHidden = !viewModel.showSubscribedSection
		
        checkmarkButton.isSelected = (viewModel.isFreeVisheoRuleAccepted)
        
		view.layoutIfNeeded();
    }
    
    private func confirmFreeSending() {
        let alertController = UIAlertController(title: NSLocalizedString("Warning", comment: "warning title"), message: NSLocalizedString("Your video will be rendered in 480p resolution.", comment: "480 p confirmation"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel"), style: .cancel, handler: nil))
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Confirm", comment: "Confirm button text"), style: .default, handler: { (action) in
            self.viewModel.sendRegularConfirmed()
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
    @IBOutlet weak var subcribeButton: UIButton!
    
    @IBOutlet weak var couponButton: UIButton!

	@IBOutlet weak var premiumCardsLabel: UILabel!
    @IBOutlet weak var menuBarItem: UIBarButtonItem!
    @IBOutlet weak var backBarItem: UIBarButtonItem!
    
    @IBOutlet weak var freeCardsSection: UIView!
    @IBOutlet weak var subscribeSection: UIView!
    @IBOutlet weak var subscribedSection: UIView!
    @IBOutlet weak var premiumCardsSection: UIView!
    @IBOutlet weak var couponSection: UIView!
    
    @IBOutlet weak var bigPackageIndicator: UIActivityIndicatorView!
    @IBOutlet weak var smallPackageIndicator: UIActivityIndicatorView!
    
    @IBOutlet weak var checkmarkButton: UIButton!
    
    @IBOutlet weak var untilDateLabel: UILabel!
	
	// MARK: Actions
    @IBAction func sendFreePressed(_ sender: Any) {
        viewModel.sendRegularConfirmed()
    }
    
    @IBAction func buySmallPressed(_ sender: Any) {
        viewModel.buySmallBundle()
    }
    
    @IBAction func buyBigPressed(_ sender: Any) {
        viewModel.buyBigBundle()
    }
    
    @IBAction func subscribeActionPassed(_ sender: Any){
        viewModel.paySubscription()
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func checkmarkPressed(_ sender: UIButton) {
        viewModel.acceptFreeRule(withSelected: !sender.isSelected)
    }
    
    @IBAction func freeRulePressed(_ sender: Any) {
        viewModel.showFreeRule()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func showCoupon(_ sender: Any) {
        viewModel.showCoupon()
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
