//
//  PremiumOccasionsCollectionMediator.swift
//  Visheo
//
//  Created by Ivan on 4/27/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit

class PremiumCollectionMediator : NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    let viewModel : PremiumOccasionsTableCellViewModel
    let occasionsCollection : UICollectionView
    
    init(viewModel: PremiumOccasionsTableCellViewModel,
         occasionsCollection: UICollectionView) {
        self.viewModel = viewModel
        self.occasionsCollection = occasionsCollection
        super.init()
        occasionsCollection.delegate = self
        occasionsCollection.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectOccasion(at: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PremiumCollectionViewCell", for: indexPath) as! PremiumCollectionViewCell
        let vm = viewModel.occasionViewModel(at: indexPath.row)
        cell.setup(with: vm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.occasionsCount
    }
}
