//
//  AuthorizationViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class AuthorizationViewController: UIViewController, RouterProxy {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: AuthorizationViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: AuthorizationViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
        
        self.viewModel.showProgressCallback = {[weak self] in
            guard let `self` = self else {return}
            if $0 {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        self.viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }

        self.viewModel.getPresentationViewController = {[weak self] in self}
    }
    
    // MARK: Actions
    
    @IBAction func facebookPressed(_ sender: Any) {
        viewModel.loginWithFacebook()
    }
    
    @IBAction func googlePressed(_ sender: Any) {
        viewModel.loginWithGoogle()
    }
    
    @IBAction func withoutRegistrationPressed(_ sender: Any) {
        viewModel.loginAsAnonymous()
    }
}

extension AuthorizationViewController {
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
