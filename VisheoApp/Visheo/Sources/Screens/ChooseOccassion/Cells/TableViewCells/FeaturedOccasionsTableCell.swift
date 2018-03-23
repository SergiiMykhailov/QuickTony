//
//  FeaturedOccasionsTableCell.swift
//  Visheo
//
//  Created by Ivan on 3/23/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit

class FeaturedOccasionsTableCell : UITableViewCell {
    @IBOutlet weak var nameLabel : UILabel!
    @IBOutlet weak var instructionLabel : UILabel!
    
    @IBOutlet weak var holidaysCollection: UICollectionView!
    var holidaysCollectionMediator : HolidaysCollectionMediator?
    
    func configure (withModel model: Any) {
        
    }
}
