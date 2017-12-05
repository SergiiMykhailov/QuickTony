//
//  AccountViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage

class AccountViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        settingsItem.isEnabled = viewModel.allowEdit
        
        viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        userPicture.sd_setImage(with: viewModel.avatarUrl, placeholderImage: #imageLiteral(resourceName: "pic"), completed: nil)
        nameLabel.text = viewModel.userName
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: AccountViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: AccountViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    // MARK: Outlets
    @IBOutlet weak var settingsItem: UIBarButtonItem!
    @IBOutlet weak var userPicture: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    
    // MARK: Actions
    
    @IBAction func settingsPressed(_ sender: Any) {
        viewModel.editAccount()
    }
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func logoutPressed(_ sender: Any) {
        viewModel.logOut()
    }
}


extension AccountViewController {
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
