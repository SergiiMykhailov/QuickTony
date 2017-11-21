    //
//  EditVisheoButton.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/21/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class EditVisheoButton: UIControl {
    
    @IBInspectable var image : UIImage? {
        didSet {
            imageView?.image = self.image
        }
    }
    
    @IBInspectable var text : String? {
        didSet {
            titleLabel?.text = self.text
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame);
        commonInit();
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        commonInit();
    }
    
    private var imageView : UIImageView?
    private var titleLabel : UILabel?
    
    private let titleFont: UIFont = UIFont(name: "Roboto-Regular", size: 12) ?? UIFont.systemFont(ofSize: 12)
    private let titleOffset : CGFloat = 8
    
    private func commonInit()
    {
        imageView = UIImageView(image: image)
        titleLabel = UILabel()
        
        titleLabel?.text = self.text
        titleLabel?.textAlignment = .center
        
        titleLabel?.font = titleFont
        titleLabel?.numberOfLines = 2
        titleLabel?.textColor = UIColor(white: 54/255, alpha: 1.0)
        
        addSubview(imageView!)
        addSubview(titleLabel!)
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews();
        if let image = image {
            imageView?.frame = CGRect(x: (frame.width - image.size.width) / 2, y: 0, width: image.size.width, height: image.size.height)
        } else {
            imageView?.frame = CGRect(x: 0, y: 0, width: frame.width, height: frame.width)
        }
        
        titleLabel?.frame = CGRect(x: 0, y: imageView!.frame.height + titleOffset, width: frame.width, height: frame.height - imageView!.frame.height - titleOffset)
    }
    
    override var isHighlighted: Bool {
        didSet {
            titleLabel?.alpha = isHighlighted ? 0.5 : 1.0
            imageView?.alpha = isHighlighted ? 0.5 : 1.0
        }
    }
}

