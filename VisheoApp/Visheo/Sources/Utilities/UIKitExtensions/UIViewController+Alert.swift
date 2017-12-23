//
//  UIViewController+Alert.swift
//
//  Created by Petro Kolesnikov on 10/2/15.
//  Copyright © 2015 Olearis. All rights reserved.
//

import UIKit

// MARK: AlertController

extension UIViewController {
    func showWarningAlertWithText(text : String) {
        showAlert(with: NSLocalizedString("Warning", comment: "Warning title"), text: text)
    }
    
    func showSuccessAlertWithText(text : String) {
        showAlert(with: NSLocalizedString("Success", comment: "Success title"), text: text)
    }
    
    func showAlert(with title: String, text : String) {
        let alert = UIAlertController(title: title, message: text, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Ok", comment: "Ok"), style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

// MARK: Toast

extension UIViewController {
    
    func showToast(message : String) {
        
        let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 100, y: self.view.frame.size.height-100, width: 200, height: 35))
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        toastLabel.textColor = UIColor.white
        toastLabel.textAlignment = .center;
        toastLabel.font = UIFont(name: "Roboto-Regular", size: 12.0)
        toastLabel.text = message
        toastLabel.alpha = 1.0
        toastLabel.layer.cornerRadius = 10;
        toastLabel.clipsToBounds  =  true
        self.view.addSubview(toastLabel)
        UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
            toastLabel.alpha = 0.0
        }, completion: {(isCompleted) in
            toastLabel.removeFromSuperview()
        })
    } }
