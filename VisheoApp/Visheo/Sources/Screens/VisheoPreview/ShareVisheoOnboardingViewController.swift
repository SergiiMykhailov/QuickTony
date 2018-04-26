//
//  ShareVisheoOnboardingViewController.swift
//  Visheo
//
//  Created by Ivan on 3/29/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

final class ShareVisheoOnboardingViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: ShareVisheoOnboardingViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: ShareVisheoOnboardingViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func okGotItButtoTapped (sender: UIButton) {
        self.viewModel.okButtonTapped()
    }
}

// MARK: - Router -
extension ShareVisheoOnboardingViewController {

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
