//
//  PagedCoverCollectionMediator.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/16/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class PagedCoverCollectionMediator : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    
    let viewModel : SelectCoverViewModel
    let coversCollection : UICollectionView
    var currentPage: Int = 0
    var containerWidth : CGFloat
    let itemsSpacing : CGFloat = 20
    
    init(viewModel: SelectCoverViewModel,
         coversCollection: UICollectionView,
         containerWidth: CGFloat) {
        self.viewModel = viewModel
        self.coversCollection = coversCollection
        self.containerWidth = containerWidth
        super.init()
        coversCollection.delegate = self
        coversCollection.dataSource = self
        
        NotificationCenter.default.addObserver(forName: .preselectedCoverChanged, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self else { return }
            strongSelf.scrollToItem(number: strongSelf.viewModel.preselectedCoverIndex)
        }
        scrollToItem(number: viewModel.preselectedCoverIndex)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "coverCell", for: indexPath) as! CoverCollectionViewCell
        let vm = viewModel.coverViewModel(at: indexPath.row)
        cell.setup(with: vm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.coversNumber
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let holidayItemSide = containerWidth - 2 * itemsSpacing
        return CGSize(width: holidayItemSide, height: holidayItemSide)
    }
    
    var skipNotification = false
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        let currentIndex = targetContentOffset.pointee.x / scrollView.frame.size.width
        skipNotification = true
        viewModel.preselectedCoverIndex = Int(currentIndex)
        skipNotification = false
    }
    
    func xOffsetForItem(at index: Int) -> CGFloat {
        return CGFloat(index) * self.coversCollection.frame.width
    }
    
    func scrollToItem(number: Int) {
        if !skipNotification {
            coversCollection.setContentOffset(CGPoint(x: xOffsetForItem(at: number), y: 0), animated: false)
        }
    }
}
