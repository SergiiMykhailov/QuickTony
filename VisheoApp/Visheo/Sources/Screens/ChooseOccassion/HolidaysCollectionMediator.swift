//
//  HolidaysCollectionMediator.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/7/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class HolidaysCollectionMediator : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let viewModel : ChooseOccasionViewModel
    let holidaysCollection : UICollectionView
    var currentPage: Int = 0
    var containerWidth : CGFloat
    let itemsSpacing : CGFloat = 10
    
    init(viewModel: ChooseOccasionViewModel,
         holidaysCollection: UICollectionView,
         containerWidth: CGFloat) {
        self.viewModel = viewModel
        self.holidaysCollection = holidaysCollection
        self.containerWidth = containerWidth
        super.init()
        holidaysCollection.delegate = self
        holidaysCollection.dataSource = self        
    }
    
    func reloadData() {
		holidaysCollection.reloadData()
		holidaysCollection.layoutIfNeeded();
		if let firstFutureIndex = viewModel.firstFutureHolidayIndex {
			scrollToItem(number: firstFutureIndex);
		}
    }
    
    var holidayPageWidth : CGFloat {
        return containerWidth - 3 * itemsSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.selectHoliday(at: indexPath.row)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "holidayCell", for: indexPath) as! HolidayCollectionViewCell
        let vm = viewModel.holidayViewModel(at: indexPath.row)
        cell.setup(with: vm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.holidaysCount
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        currentPage = Int(floor((holidaysCollection.contentOffset.x - holidayPageWidth / 2) / holidayPageWidth) + 1)
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        var newPage = currentPage
        
        if velocity.x == 0 {
            newPage = Int(floor((targetContentOffset.pointee.x - holidayPageWidth / 2) / holidayPageWidth) + 1);
        }
        else {
            newPage = velocity.x > 0 ? currentPage + 1 : currentPage - 1;
            if newPage < 0 {
                newPage = 0
            }
            if newPage > Int(holidaysCollection.contentSize.width / holidayPageWidth) {
                newPage = Int(ceil(holidaysCollection.contentSize.width / holidayPageWidth)) - 1
            }
        }
        
        targetContentOffset.pointee = CGPoint(x: CGFloat(newPage) * holidayPageWidth, y: targetContentOffset.pointee.y)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let holidayItemSide = containerWidth - 4 * itemsSpacing
        return CGSize(width: holidayItemSide, height: holidayItemSide)
    }
    
    func scrollToItem(number: Int) {
		let indexPath = IndexPath(item: number, section: 0);
		guard let layout = holidaysCollection.collectionViewLayout as? UICollectionViewFlowLayout,
			let frame = layout.layoutAttributesForItem(at: indexPath)?.frame else {
			return;
		}
		let offset = frame.origin.x - layout.sectionInset.left;
		holidaysCollection.setContentOffset(CGPoint(x: offset, y: 0.0), animated: false)
    }
}
