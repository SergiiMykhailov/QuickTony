//
//  ShareVisheoViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class ShareVisheoViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.creationStatusChanged = {[weak self] in
            self?.updateProgress()
        }
    }

    func updateProgress() {
        switch viewModel.creationStatus {
        case .rendering(let progress):
            progressBar.title = viewModel.renderingTitle
            progressBar.progress = progress
        case .uploading(let progress):
            progressBar.title = viewModel.uploadingTitle
            progressBar.progress = progress
        case .ready:
            break //TODO: Hide progress animated, enable components(in differnet function)
        }
    }
    //MARK: - VM+Router init
    
    private(set) var viewModel: ShareViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: ShareViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func press(_ sender: Any) {
        progressBar.set(progress: (progressBar.progress + 0.1).truncatingRemainder(dividingBy: 1), animated: true)
    }
    
    @IBOutlet weak var progressBar: LabeledProgressView!
    
}

extension ShareVisheoViewController {
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
