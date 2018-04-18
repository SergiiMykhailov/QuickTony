//
//  SubscriptionDescriptionViewController.swift
//  Visheo
//
//  Created by Ivan on 4/18/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit
import MBProgressHUD

final class SubscriptionDescriptionViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: SubscriptionDescriptionViewModel!
    private(set) var router: FlowRouter!

    @IBOutlet var descriptionLabel: UILabel!
    
    // MARK: - Configuration -

    func configure(viewModel: SubscriptionDescriptionViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        self.descriptionLabel.text = viewModel.subscribptionDescription
        
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
    }

    @IBAction func gotItButtonPressed(sender: UIButton){
        viewModel.paySubscription()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Router -
extension SubscriptionDescriptionViewController {

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

extension SubscriptionDescriptionViewController: SubscriptionDescriptionViewModelDelegate {
    

    func refreshUI() {
        self.descriptionLabel.text = viewModel.subscribptionDescription
    }

}
