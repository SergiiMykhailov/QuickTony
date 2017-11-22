//
//  FilmstripCoversCollectionMediator.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class FilmstripCoversCollectionMediator : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let viewModel : SelectCoverViewModel
    let coversCollection : UICollectionView
    
    init(viewModel: SelectCoverViewModel,
         coversCollection: UICollectionView) {
        self.viewModel = viewModel
        self.coversCollection = coversCollection
        super.init()
        coversCollection.delegate = self
        coversCollection.dataSource = self
        
        NotificationCenter.default.addObserver(forName: .preselectedCoverChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self else { return }
            strongSelf.scrollToItem(number: strongSelf.viewModel.preselectedCoverIndex)
        }
        
        scrollToItem(number: viewModel.preselectedCoverIndex)
    }
    
    func relayout() {
        if let flowLayout = coversCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            let horizontalInset = (coversCollection.frame.width - flowLayout.itemSize.width) / 2
            flowLayout.sectionInset = UIEdgeInsetsMake(0, horizontalInset, 0, horizontalInset)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.preselectedCoverIndex = indexPath.item
        scrollToItem(number: indexPath.item)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.coversNumber
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as! CoverCollectionViewCell
        let vm = viewModel.coverViewModel(at: indexPath.row)
        cell.setup(with: vm)
        return cell
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if let flowLayout = self.coversCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            let targetOffset = targetContentOffset.pointee
            let itemWidth = flowLayout.itemSize.width + flowLayout.minimumLineSpacing
            var itemNum = targetOffset.x / itemWidth
            
            if velocity.x == 0 {
                itemNum = round(itemNum)
            } else if velocity.x > 0 {
                itemNum = ceil(itemNum)
            } else {
                itemNum = floor(itemNum)
            }
            
            if itemNum < 0 {
                itemNum = 0
            }
            if itemNum > scrollView.contentSize.width / itemWidth {
                itemNum = ceil(scrollView.contentSize.width / itemWidth) - 1
            }
            
            targetContentOffset.pointee = CGPoint(x: itemNum * itemWidth, y: targetContentOffset.pointee.y)
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if let flowLayout = self.coversCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            let itemWidth = flowLayout.itemSize.width + flowLayout.minimumLineSpacing
            let itemNum = scrollView.contentOffset.x / itemWidth
            viewModel.preselectedCoverIndex = Int(itemNum)
        }
    }
    
    func xOffsetForItem(at index: Int) -> CGFloat {
        if let flowLayout = self.coversCollection.collectionViewLayout as? UICollectionViewFlowLayout {
            let itemWidth = flowLayout.itemSize.width + flowLayout.minimumLineSpacing
            
            return CGFloat(index) * itemWidth
        }
        return 0
    }

    func scrollToItem(number: Int) {
        coversCollection.setContentOffset(CGPoint(x: xOffsetForItem(at: number), y: 0), animated: true)
    }
}
