//
//  VisheoPreviewViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class VisheoPreviewViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        tempImage.image = viewModel.coverImage
    }
    
    override func viewWillAppear(_ animated: Bool) {
        tempImage.image = viewModel.coverImage
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: PreviewViewModel!
    private(set) var router: FlowRouter!
    
    @IBOutlet weak var tempImage: UIImageView!
    
    func configure(viewModel: PreviewViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func editCover(_ sender: Any) {
        viewModel.editCover()
    }
}


extension VisheoPreviewViewController {
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
