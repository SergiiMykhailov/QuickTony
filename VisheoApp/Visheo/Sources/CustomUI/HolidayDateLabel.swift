//
//  SuperLabel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class HolidayDateLabel: UILabel {

    @IBInspectable var horizontalInset : CGFloat = 0
    
    var inset: UIEdgeInsets {
        return UIEdgeInsetsMake(0, horizontalInset, 0, horizontalInset)
    }
    
    override func drawText(in rect: CGRect) {
        super.drawText(in: UIEdgeInsetsInsetRect(rect, inset))
    }
    
    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.width += inset.right + inset.left
        size.height += inset.top + inset.bottom
        return size
    }
}
