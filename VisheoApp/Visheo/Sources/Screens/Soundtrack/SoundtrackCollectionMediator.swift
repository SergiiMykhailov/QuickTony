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
}
