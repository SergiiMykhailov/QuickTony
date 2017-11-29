//
//  UIViewController+Alert.swift
//
//  Created by Petro Kolesnikov on 10/2/15.
//  Copyright © 2015 Olearis. All rights reserved.
//

import UIKit


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
