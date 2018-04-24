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
	private let practicesCollectionView: UICollectionView;
	private let viewModel: TipsViewModel;
	private let containerWidth: CGFloat;
	var currentPage: Int = 0
	let itemsSpacing : CGFloat = 10
	
	init(viewModel: TipsViewModel, practicesCollectionView: UICollectionView, containerWidth: CGFloat) {
		self.viewModel = viewModel;
		self.practicesCollectionView = practicesCollectionView;
		self.containerWidth = containerWidth;
		
		super.init();
		
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
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.numberOfItems();
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
	{
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "bestPracticeCell", for: indexPath) as! BestPracticeCollectionViewCell;
        let model = viewModel.practiceTipCellModel(at: indexPath.row);
        cell.setup(with: model);
        return cell;
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: containerWidth, height: 50.0);
	}
}
