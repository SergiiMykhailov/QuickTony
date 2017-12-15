//
//  AuthorizationViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/2/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class AuthorizationViewController: UIViewController, RouterProxy {

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTextViewLinks()
        
        if !viewModel.anonymousAllowed {
            skipRegistrationBottomConstraint.constant = 0
            skipRegistrationHeightConstraint.constant = 0
            signInBottomConstraint.constant = 31
        } else {
            signUpMandatoryLabel.isHidden = true
            signUpMandatoryLabel.text = ""
        }
        
        closeButton.isHidden = !viewModel.cancelAllowed
        if let description = viewModel.descriptionString {
            authReasonlabel.text = description
        }
    }
    
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var authReasonlabel: UILabel!
    @IBOutlet weak var signUpMandatoryLabel: UILabel!
    @IBOutlet weak var signInBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var skipRegistrationHeightConstraint: NSLayoutConstraint!
    @IBOutlet weak var skipRegistrationBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var signInUpLabel: UILabel!
	//MARK: - VM+Router init
    
    private(set) var viewModel: AuthorizationViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: AuthorizationViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
        
        self.viewModel.showProgressCallback = {[weak self] in
            guard let `self` = self else {return}
            if $0 {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        self.viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }

        self.viewModel.getPresentationViewController = {[weak self] in self}
    }
    
    // MARK: Actions
    
    @IBAction func closePressed(_ sender: Any) {
        viewModel.cancel()
    }
    
    @IBAction func facebookPressed(_ sender: Any) {
        viewModel.loginWithFacebook()
    }
    
    @IBAction func googlePressed(_ sender: Any) {
        viewModel.loginWithGoogle()
    }
    
    @IBAction func withoutRegistrationPressed(_ sender: Any) {
        viewModel.loginAsAnonymous()
    }
    
    func signInPressed() {
        viewModel.signIn()
    }
    
    func signUpPressed() {
        viewModel.signUp()
    }
}

extension AuthorizationViewController {
    func configureTextViewLinks() {
        let mutable  = NSMutableAttributedString(attributedString: signInUpLabel.attributedText!)
        let signInRange = mutable.mutableString.range(of: "Sign In")
        let signUpRange = mutable.mutableString.range(of: "Sign Up")
	
        mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: signUpRange)
        mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.styleSingle.rawValue, range: signInRange)
		
        signInUpLabel.attributedText = mutable
		
		let recognizer = UITapGestureRecognizer(target: self, action: #selector(AuthorizationViewController.tappedLabel(with:)))
		signInUpLabel.addGestureRecognizer(recognizer)
    }
	
	@objc private func tappedLabel(with recognizer: UITapGestureRecognizer) {
		guard let text = signInUpLabel.attributedText?.string, let signInRange = text.range(of: "Sign In"), let signUpRange = text.range(of: "Sign Up") else {
			return;
		}
		
		if recognizer.didTapAttributedTextInLabel(label: signInUpLabel, inRange: NSRange(signInRange, in: text)) {
			signInPressed();
		} else if recognizer.didTapAttributedTextInLabel(label: signInUpLabel, inRange: NSRange(signUpRange, in: text)) {
			signUpPressed();
		}
	}
}

extension AuthorizationViewController {
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
