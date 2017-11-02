//
//  LaunchProxyViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 10/31/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class LaunchProxyViewController: UIViewController, RouterProxy {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: LaunchProxyViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: LaunchProxyViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
}

extension LaunchProxyViewController {
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