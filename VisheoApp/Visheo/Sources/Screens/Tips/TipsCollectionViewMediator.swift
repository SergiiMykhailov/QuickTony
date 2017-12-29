//
//  TipsCollectionViewMediator.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class TipsCollectionViewMediator: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
	private let wordIdeasCollectionView: UICollectionView;
	private let practicesCollectionView: UICollectionView;
	private let viewModel: TipsViewModel;
	private let containerWidth: CGFloat;
	var currentPage: Int = 0
	let itemsSpacing : CGFloat = 10
	
	init(viewModel: TipsViewModel, wordIdeasCollectionView: UICollectionView, practicesCollectionView: UICollectionView, containerWidth: CGFloat) {
		self.viewModel = viewModel;
		self.wordIdeasCollectionView = wordIdeasCollectionView;
		self.practicesCollectionView = practicesCollectionView;
		self.containerWidth = containerWidth;
		
		super.init();
		
		let wordsLayout = AlignedFlowLayout(alignment: .top);
		wordsLayout.minimumInteritemSpacing = 10.0;
		wordsLayout.minimumLineSpacing = 0.0;
		wordsLayout.scrollDirection = .horizontal;
		wordsLayout.sectionInset = UIEdgeInsetsMake(0.0, 20.0, 0.0, 20.0);
		
		wordIdeasCollectionView.collectionViewLayout = wordsLayout;
		wordIdeasCollectionView.delegate = self;
		wordIdeasCollectionView.dataSource = self;
		
		let practicesLayout = AutoSizingLayout();
		practicesLayout.scrollDirection = .vertical;
		practicesLayout.minimumInteritemSpacing = 20.0;
		practicesLayout.minimumLineSpacing = 20.0;
		practicesLayout.sectionInset = UIEdgeInsetsMake(0.0, 0.0, 20.0, 0.0);
		practicesLayout.estimatedItemSize = CGSize(width: containerWidth, height: 50.0);
		
		practicesCollectionView.collectionViewLayout = practicesLayout;
		practicesCollectionView.delegate = self;
		practicesCollectionView.dataSource = self;
	}
	
	func handleContentChange() {
		guard let layout = wordIdeasCollectionView.collectionViewLayout as? UICollectionViewFlowLayout else {
			return;
		}
		
		var insets = layout.sectionInset;
		if viewModel.numberOfItems(for: .words) < 2 {
			insets.left = (containerWidth - wordPageWidth) / 2.0;
		} else {
			insets.left = 20.0;
		}
		insets.right = insets.left;
		layout.sectionInset = insets;
		layout.invalidateLayout();
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		switch collectionView {
			case wordIdeasCollectionView:
				return viewModel.numberOfItems(for: .words);
			case practicesCollectionView:
				return viewModel.numberOfItems(for: .practices);
			default:
				return 0;
		}
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
		if collectionView == wordIdeasCollectionView {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "wordIdeaCell", for: indexPath) as! WordIdeaCollectionViewCell;
			let model = viewModel.wordTipCellModel(at: indexPath.row);
			cell.setup(with: model);
			return cell;
		}
		
		if collectionView == practicesCollectionView {
			let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bestPracticeCell", for: indexPath) as! BestPracticeCollectionViewCell;
			let model = viewModel.practiceTipCellModel(at: indexPath.row);
			cell.setup(with: model);
			return cell;
		}
		
		return UICollectionViewCell();
	}
	
	var wordPageWidth : CGFloat {
		return containerWidth - 3 * itemsSpacing
	}
	
	func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
		if scrollView != wordIdeasCollectionView { return }
		currentPage = Int(floor((wordIdeasCollectionView.contentOffset.x - wordPageWidth / 2) / wordPageWidth) + 1)
	}
	
	func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
		if scrollView != wordIdeasCollectionView { return }
		
		var newPage = currentPage
		
		if velocity.x == 0 {
			newPage = Int(floor((targetContentOffset.pointee.x - wordPageWidth / 2) / wordPageWidth) + 1);
		}
		else {
			newPage = velocity.x > 0 ? currentPage + 1 : currentPage - 1;
			if newPage < 0 {
				newPage = 0
			}
			if newPage > Int(wordIdeasCollectionView.contentSize.width / wordPageWidth) {
				newPage = Int(ceil(wordIdeasCollectionView.contentSize.width / wordPageWidth)) - 1
			}
		}
		
		var offset: CGFloat = 0.0;
		if let layout = wordIdeasCollectionView.collectionViewLayout as? UICollectionViewFlowLayout, let frame = layout.layoutAttributesForItem(at: IndexPath(item: newPage, section: 0))?.frame {
			offset = frame.origin.x
			offset -= layout.sectionInset.left;
		}

		targetContentOffset.pointee = CGPoint(x: offset, y: targetContentOffset.pointee.y)
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		switch collectionView {
			case wordIdeasCollectionView:
				let holidayItemSide = containerWidth - 4 * itemsSpacing
				return CGSize(width: holidayItemSide, height: holidayItemSide)
			case practicesCollectionView:
				return CGSize(width: containerWidth, height: 50.0);
			default:
				return CGSize.zero;
		}
	}
}
