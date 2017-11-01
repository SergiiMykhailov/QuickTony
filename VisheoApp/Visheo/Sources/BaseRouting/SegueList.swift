//
//  SegueList.swift
//
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol SegueListType {

    var rawValue: String { get }

    init?(rawValue: String)
    init?(segue: UIStoryboardSegue)

}

extension SegueListType {
    init?(segue: UIStoryboardSegue) {
        guard
            let identifier = segue.identifier,
            let newSegue = Self.init(rawValue: identifier) else
        {
            return nil
        }

        self = newSegue
    }
}

extension UIViewController {
    func performSegue(_ segue: SegueListType, sender: Any?) {
        self.performSegue(withIdentifier: segue.rawValue, sender: sender)
    }
}
