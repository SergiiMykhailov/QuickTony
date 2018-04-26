//
//  OccassionsCollectionMediator.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class OccassionsCollectionMediator : NSObject, UICollectionViewDelegate, UICollectionViewDataSource {
    let viewModel : StandardOccasionsTableCellViewModel
    let occasionsCollection : UICollectionView
    
    init(viewModel: StandardOccasionsTableCellViewModel,
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
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "occassionCell", for: indexPath) as! OccassionCollectionViewCell
        let vm = viewModel.occasionViewModel(at: indexPath.row)
        cell.setup(with: vm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.occasionsCount
    }
}
