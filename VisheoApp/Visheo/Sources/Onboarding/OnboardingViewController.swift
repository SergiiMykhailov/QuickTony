//
//  OnboardingViewController.swift
//  
//
//  Created by Petro Kolesnikov on 11/1/17.
//

import UIKit

class OnboardingViewController: UIViewController, UIScrollViewDelegate {

    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        pageControl.transform = CGAffineTransform(scaleX: 1.65, y: 1.65)
    }

    // MARK: Scroll view delegate
    
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
}
