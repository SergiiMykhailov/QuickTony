//
//  SignInViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/3/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class SignInViewController: UIViewController, RouterProxy {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var contentScroll: UIScrollView!
    @IBOutlet weak var signInButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel.didChangeCallback = {[weak self] in
            let enableSignIn = self?.viewModel.canSignIn ?? false
            self?.signInButton.isEnabled = enableSignIn
            self?.signInButton.alpha = enableSignIn ? 1.0 : 0.5
        }
        
        viewModel.showProgressCallback = {[weak self] in
            if let view = self?.view {
                if $0 {
                    MBProgressHUD.showAdded(to: view, animated: true)
                } else {
                    MBProgressHUD.hide(for: view, animated: true)
                }
            }
        }
        
        viewModel.warningAlertHandler = { [weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: SignInViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: SignInViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    override func viewWillAppear(_ animated: Bool) {
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.textFieldChanged(notification:)), name: .UITextFieldTextDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillHide(notification:)), name: .UIKeyboardWillHide, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(SignUpViewController.keyboardWillShow(notification:)), name: .UIKeyboardWillShow, object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let userInfo = notification.userInfo,
            let endFrame = (userInfo[UIKeyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue,
            let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue {
            
            UIView.animate(withDuration: duration, animations: {
                let keyboardHeight = endFrame.height
                self.contentScroll.contentInset.bottom = keyboardHeight
                self.contentScroll.scrollIndicatorInsets.bottom = keyboardHeight
            })
        }
    }
    
    @objc func keyboardWillHide(notification: NSNotification) {
        let duration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        
        UIView.animate(withDuration: duration, animations: {
            self.contentScroll.contentInset.bottom = 0
            self.contentScroll.scrollIndicatorInsets.bottom = 0
        })
    }
    
    // MARK: Actions
    
    @IBAction func forgotPaswordTapped(_ sender: Any) {
    }
    
    @IBAction func signInTapped(_ sender: Any) {
        viewModel.signIn()
    }
    
    @IBAction func backTapped(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension SignInViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == emailField {
            passwordField.becomeFirstResponder()
        } else {
            textField.endEditing(true)
            if viewModel.canSignIn {
                signInTapped(textField)
            }
        }
        return true
    }
    
    @objc func textFieldChanged(notification: NSNotification) {
        guard let textField = notification.object as? UITextField else {return}
        if textField == emailField {
            viewModel.email = textField.text ?? ""
        } else {
            viewModel.password = textField.text ?? ""
        }
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
