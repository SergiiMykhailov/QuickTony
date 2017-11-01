//
//  LaunchProxyViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 10/31/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class LaunchProxyViewController: UIViewController, RouterProxy {

    private(set) var viewModel: LaunchProxyViewModel!
    private(set) var router: FlowRouter!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    //MARK: - Init
    
    func configure(viewModel: LaunchProxyViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
}

