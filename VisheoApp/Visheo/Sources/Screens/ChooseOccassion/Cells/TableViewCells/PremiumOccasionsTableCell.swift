//
//  PremiumOccasionsTableCell.swift
//  Visheo
//
//  Created by Ivan on 4/27/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit

class PremiumOccasionsTableCell : UITableViewCell {
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var instructionLabel : UILabel!
    @IBOutlet weak var occasionsCollection: UICollectionView!
    
    var occasionsCollectionMediator : PremiumCollectionMediator?
    
    func configure(withModel model: PremiumOccasionsTableCellViewModel,
                   mediator: PremiumCollectionMediator) {
        occasionsCollectionMediator = mediator
        nameLabel.text = model.title
        instructionLabel.text = model.subTitle
        instructionLabel.isHidden = model.subTitle == nil
    }
}
