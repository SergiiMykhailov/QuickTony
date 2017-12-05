//
//  EditAccountViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class EditAccountViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nameField.text = viewModel.userName
        
        viewModel.showProgressCallback = {[weak self] in
            guard let `self` = self else {return}
            if $0 {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
        
        viewModel.successAlertHandler = {[weak self] in
            self?.showSuccessAlertWithText(text: $0)
        }
        
        viewModel?.requiredFieldAlertHandler = {[weak self] in
            self?.showAlert(with: NSLocalizedString("Required Field", comment: "required field alert title"), text: $0)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.UITextFieldTextDidChange, object: nameField, queue: OperationQueue.main) {[weak self] (notification) in
            if let `self` = self {
                self.viewModel.userName = self.nameField.text ?? ""
            }
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(EditAccountViewController.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(EditAccountViewController.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: EditAccountViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: EditAccountViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    // MARK: Outlets
    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var deleteBottomConstraint: NSLayoutConstraint!
    
    // MARK: Actions    
    @IBAction func deletePressed(_ sender: Any) {
        let alertController = UIAlertController(title: NSLocalizedString("Warning", comment: "warning title"), message: NSLocalizedString("Your account with all the data will be deleted without possiblity to restore. Proceed?", comment: "Confirm account deletion alert message"), preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: "Cancel button"), style: .cancel, handler: nil))
        
        alertController.addAction(UIAlertAction(title: NSLocalizedString("Proceed", comment: "Confirm account deletion alert button"), style: .destructive, handler: { (action) in
            self.viewModel.deleteAccount()
        }))
        present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func savePressed(_ sender: Any) {
        viewModel.saveEditing()
    }
    
    // MARK: Keyboard observing
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo,
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
            
            UIView.animate(withDuration: duration, animations: {
                let keyboardHeight = endFrame.height
                self.deleteBottomConstraint.constant = 20 + keyboardHeight
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        
        UIView.animate(withDuration: duration, animations: {
            self.deleteBottomConstraint.constant = 20
        })
    }
}

extension EditAccountViewController {
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
