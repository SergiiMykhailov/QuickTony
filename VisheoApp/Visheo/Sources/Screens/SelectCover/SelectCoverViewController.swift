//
//  SelectCoverViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/12/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import MBProgressHUD

class SelectCoverViewController: UIViewController {

    @IBOutlet weak var pagedCoversCollection: UICollectionView!
    @IBOutlet weak var coversFilmstripCollection: UICollectionView!
	@IBOutlet weak var cancelBarButtonItem: UIBarButtonItem!
	
    var pagedCoversCollectionMediator : PagedCoverCollectionMediator?
    var filmstripCoversCollectionMediator : FilmstripCoversCollectionMediator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
		
		automaticallyAdjustsScrollViewInsets = false;

        pagedCoversCollectionMediator = PagedCoverCollectionMediator(viewModel: viewModel,
                                                                     coversCollection: pagedCoversCollection,
                                                                     containerWidth: self.view.frame.width)
        
        filmstripCoversCollectionMediator = FilmstripCoversCollectionMediator(viewModel:  viewModel,
                                                                              coversCollection: coversFilmstripCollection)
        
        self.viewModel.showProgressCallback = {[weak self] in
            guard let `self` = self else {return}
            if $0 {
                MBProgressHUD.showAdded(to: self.view, animated: true)
            } else {
                MBProgressHUD.hide(for: self.view, animated: true)
            }
        }
        
        self.viewModel.warningAlertHandler = {[weak self] in
            self?.showWarningAlertWithText(text: $0)
        }
		
		viewModel.didChangeCallback = { [weak self] in
			self?.pagedCoversCollection.reloadData();
			self?.coversFilmstripCollection.reloadData();
		}
        
        if viewModel.hideBackButton {
            self.navigationItem.leftBarButtonItem = nil
        }
		
		navigationItem.rightBarButtonItem = viewModel.canCancelSelection ? cancelBarButtonItem : nil;
    }
    
    override func viewDidLayoutSubviews() {
        filmstripCoversCollectionMediator?.relayout()
    }

    //MARK: - VM+Router init
    
    private(set) var viewModel: SelectCoverViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: SelectCoverViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    
    @IBAction func likeCoverPressed(_ sender: Any) {
        viewModel.selectCover()
    }
    
    @IBAction func backPressed(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
	
	@IBAction func cancelPressed(_ sender: Any) {
		viewModel.cancel();
	}
}

extension SelectCoverViewController {
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
