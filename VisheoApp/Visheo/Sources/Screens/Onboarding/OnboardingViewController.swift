//
//  OnboardingViewController.swift
//  
//
//  Created by Petro Kolesnikov on 11/1/17.
//

import UIKit

class OnboardingViewController: UIViewController, UIScrollViewDelegate, RouterProxy {
    @IBOutlet weak var pageControl: UIPageControl!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        pageControl.transform = CGAffineTransform(scaleX: 1.65, y: 1.65)
    }
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: OnboardingViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: OnboardingViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    // MARK: Scroll view delegate
        
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageNumber = round(scrollView.contentOffset.x / scrollView.frame.size.width)
        pageControl.currentPage = Int(pageNumber)
    }
    
    // MARK: Actions
    
    @IBAction func gotItPressed(_ sender: Any) {
        viewModel.onBoardingSeen()
    }
}

extension OnboardingViewController {
    //MARK: - Routing
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        router.prepare(for: segue, sender: sender)
    }
}
