//
//  PrompterOnboardingViewController.swift
//  Visheo
//
//  Created by Ivan on 5/2/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

final class PrompterOnboardingViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: PrompterOnboardingViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PrompterOnboardingViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func goBack(){
        self.viewModel.goBack()
        self.navigationController?.popViewController(animated: true)
    }
}

// MARK: - Router -
extension PrompterOnboardingViewController {

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
