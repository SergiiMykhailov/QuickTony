//
//  PhotoSelectionIndexView.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/17/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit



@IBDesignable
class PhotoSelectionIndexView: UIView {
    enum SelectionState {
        case none
        case selected(index: Int)
    }
    
    var selectionState : SelectionState = .none {
        didSet {
            setNeedsDisplay()
        }
    }
    @IBInspectable var selectedColor: UIColor = UIColor.red
    @IBInspectable var deselectedColor: UIColor = UIColor.white
    
    var indexFont: UIFont = UIFont(name: "Roboto-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
    
    override func prepareForInterfaceBuilder() {
        selectionState = .none
    }

    override func draw(_ rect: CGRect) {
        // Drawing code
        if let context = UIGraphicsGetCurrentContext() {
            switch selectionState {
            case .none:
                deselectedColor.setStroke()
                context.strokeEllipse(in: rect)
            case .selected(let index):
                selectedColor.setFill()
                context.fillEllipse(in: rect)
                draw(index: index, on: context, in: rect)
            }
        }
    }
    
    private func draw(index: Int, on context: CGContext, in rect: CGRect) {
        
        let attributedString = NSAttributedString(string: "\(index)", attributes: [NSAttributedStringKey.font : indexFont, NSAttributedStringKey.foregroundColor : UIColor.white])
        
        let bounding =  attributedString.boundingRect(with: rect.size, context: nil)
        let vInset = (rect.height - bounding.height)/2
        let hInset = (rect.width - bounding.width)/2
        attributedString.draw(in: rect.insetBy(dx: hInset, dy: vInset))
    }
 

}
