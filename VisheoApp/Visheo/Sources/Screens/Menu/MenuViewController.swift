//
//  MenuViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import SDWebImage

class MenuViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        NotificationCenter.default.addObserver(self, selector: #selector(MenuViewController.willBeShown), name: Notification.Name.LGSideMenuWillShowLeftView, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userPicImage: UIImageView!
    
    @objc func willBeShown() {
        usernameLabel.text = viewModel.username
        userPicImage.sd_setImage(with: viewModel.userPicture, placeholderImage: #imageLiteral(resourceName: "pic"), options: [], completed: nil)
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: MenuViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: MenuViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
}

extension MenuViewController : UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.menuItemsCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "menuItem", for: indexPath) as! MenuTableViewCell
        
        cell.setup(with: viewModel.menuItem(at: indexPath.row))
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectMenu(at: indexPath.row)
    }
}

extension MenuViewController {
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