//
//  SignInViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class SignInViewController: UIViewController, RouterProxy {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: SignInViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: SignInViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
}

extension SignInViewController {
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
