//
//  PhotoPermissionsViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class PhotoPermissionsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: PhotoPermissionsViewModel!
    private(set) var router: FlowRouter!

    func configure(viewModel: PhotoPermissionsViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func allowAccessPressed(_ sender: Any) {
        viewModel.allowAccess()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func skipPressed(_ sender: Any) {
        viewModel.skipPhotos()
    }    
}

extension PhotoPermissionsViewController {
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


