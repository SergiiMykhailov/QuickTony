//
//  PrompterCollectionViewCell.swift
//  Visheo
//
//  Created by Ivan on 5/2/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit

class PrompterCollectionViewCell: UICollectionViewCell {
    
    @IBOutlet weak var textLabel: UILabel!
    
    func setup(withText text: String) {
        textLabel.text = text
    }
    
}
