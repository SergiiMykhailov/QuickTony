//
//  StandartOccasionsTableCell.swift
//  Visheo
//
//  Created by Ivan on 3/23/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit

class StandartOccasionsTableCell : UITableViewCell {
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var occasionsCollection: UICollectionView!
    
    var occasionsCollectionMediator : OccassionsCollectionMediator?
    
    func configure(withModel model: Any) {
        
    }
}

