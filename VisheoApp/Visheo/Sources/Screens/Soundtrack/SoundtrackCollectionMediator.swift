//
//  SoundtrackCollectionMediator.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class SoundtrackCollectionMediator: NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout
{
	let viewModel : SelectSoundtrackViewModel;
	let collectionView : UICollectionView;
	let containerWidth: CGFloat;
	
	init(viewModel: SelectSoundtrackViewModel,
		 collectionView: UICollectionView,
		 containerWidth: CGFloat)
	{
		self.viewModel = viewModel;
		self.collectionView = collectionView;
		self.containerWidth = containerWidth;
		
		super.init();
		self.collectionView.delegate = self;
		self.collectionView.dataSource = self;
	}
	
	
	func updateCollectionContents(at indexPath: IndexPath?) {
		if let `indexPath` = indexPath {
			let model = viewModel.soundtrackCellModel(at: indexPath.row);
			let cell = collectionView.cellForItem(at: indexPath) as? SoundtrackCollectionViewCell;
			cell?.setup(with: model);
		} else {
			collectionView.reloadData();
		}
	}
	
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return viewModel.soundtracksCount;
	}
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "soundtrackCell", for: indexPath) as! SoundtrackCollectionViewCell
		let vm = viewModel.soundtrackCellModel(at: indexPath.row);
		cell.setup(with: vm)
		return cell
	}
	
	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: collectionView.bounds.width, height: 66.0);
	}
	
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		viewModel.selectSoundtrack(at: indexPath.row);
		collectionView.reloadData();
	}
}
