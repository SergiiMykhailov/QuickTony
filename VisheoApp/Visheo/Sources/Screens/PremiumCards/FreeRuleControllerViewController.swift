//
//  FreeRuleControllerViewController.swift
//  Visheo
//
//  Created by Ivan on 3/21/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

final class FreeRuleControllerViewController: UIViewController {
    
    @IBAction func gotItButtonPressed(_ sender:UIButton!) {
        navigationController?.popViewController(animated:true)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true);
    }
}

