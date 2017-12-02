//
//  SelectSoundtrackViewController.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class SelectSoundtrackViewController: UIViewController {
	@IBOutlet weak var progressViewTopConstraint: NSLayoutConstraint!
	@IBOutlet weak var progressViewBottomConstraint: NSLayoutConstraint!
	@IBOutlet weak var downloadProgressView: LabeledProgressView!
    
	@IBOutlet weak var soundtracksCollectionView: UICollectionView!
	var soundtracksCollectionMediator : SoundtrackCollectionMediator?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		soundtracksCollectionMediator = SoundtrackCollectionMediator(viewModel: viewModel,
																	 collectionView: soundtracksCollectionView,
																	 containerWidth: view.bounds.width);
		
		viewModel.bufferProgressChanged = { [weak self] indexPath in
			DispatchQueue.main.async {
				self?.soundtracksCollectionMediator?.updateCollectionContents(at: indexPath);
			}
		}
		
		viewModel.downloadStateChanged = { [weak self] state in
			DispatchQueue.main.async {
				self?.handleDownloadStateChange(state);
			}
		}
	}
	
	private(set) var viewModel: SelectSoundtrackViewModel!
	private(set) var router: FlowRouter!
	
	func configure(viewModel: SelectSoundtrackViewModel, router: FlowRouter) {
		self.viewModel = viewModel
		self.router    = router
	}

	
	@IBAction func confirmSelection() {
		viewModel.confirmSelection();
	}
	
	@IBAction func cancelSelection(_ sender: UIBarButtonItem) {
		viewModel.cancelSelection();
	}
	
	private func handleDownloadStateChange(_ state: SoundtrackDownloadState) {
		if case .downloading(let progress) = state {
			downloadProgressView.progress = progress;
		}
		
		downloadProgressView.title = viewModel.statusText(for: state);
		
		UIView.animate(withDuration: 0.3, delay: 0.0, options: [.curveEaseInOut, .beginFromCurrentState],
					   animations: {
			self.updatePresentation(state: state);
			self.view.layoutIfNeeded()
		}, completion: nil);
	}
	
	private func updatePresentation(state: SoundtrackDownloadState) {
		switch state {
			case .downloading,
				 .failed:
				downloadProgressView.alpha = 1.0;
				progressViewTopConstraint.isActive = true;
				progressViewBottomConstraint.isActive = false;
			default:
				downloadProgressView.alpha = 0.0;
				progressViewTopConstraint.isActive = false;
				progressViewBottomConstraint.isActive = true;
		}
	}
}
