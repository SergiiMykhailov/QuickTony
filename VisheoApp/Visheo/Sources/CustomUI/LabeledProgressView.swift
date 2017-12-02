//
//  LabeledProgressView.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/24/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

@IBDesignable
class LabeledProgressView: UIView {

    private let progressLayer = CALayer();
    private let titleLabel = UILabel()
    
    private let titleHeight : CGFloat = 20
    private let titleInset : CGFloat = 8
    
    @IBInspectable var progressColor: UIColor = .red {
        didSet {
            progressLayer.backgroundColor = progressColor.cgColor;
        }
    }
    
    @IBInspectable
    var title : String? {
        didSet {
            titleLabel.text = title
        }
    }
    
    @IBInspectable
    var progress: Double = 0.0 {
        didSet {
            progressLayer.frame = progressFrame
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
    
    private func commonInit()
    {
        progressLayer.backgroundColor = progressColor.cgColor;
        layer.addSublayer(progressLayer);
        
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont(name: "Roboto-Medium", size: 16)
        titleLabel.textAlignment = .center
        titleLabel.adjustsFontSizeToFitWidth = true
        
        addSubview(titleLabel)
    }
    
    private var progressFrame : CGRect {
        return CGRect(x: 0, y: 0, width: frame.width * CGFloat(progress), height: frame.height)
    }
    
    override func layoutSubviews() {
        progressLayer.frame = progressFrame
        titleLabel.frame = CGRect(x: titleInset, y: frame.height/2 - titleHeight/2, width: frame.width - 2 * titleInset, height: titleHeight)
    }
    
    func set(progress: Double, animated: Bool) {
        if animated {
            CATransaction.begin()
        }
        self.progress = progress
        progressLayer.frame = progressFrame
        if animated {
            CATransaction.commit()
        }
    }
}
