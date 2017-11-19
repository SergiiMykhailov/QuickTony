//
//  PhotoCollectionViewCell.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class PhotoCollectionViewCell: UICollectionViewCell {
    @IBOutlet var imageView: UIImageView!
    @IBOutlet weak var indexView: PhotoSelectionIndexView!
    
    var representedAssetIdentifier: String!
    
}
