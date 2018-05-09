//
//  PrompterWordsCollectionMediator.swift
//  Visheo
//
//  Created by Ivan on 5/2/18.
//  Copyright © 2018 Olearis. All rights reserved.
//

import UIKit

class PrompterWordsCollectionMediator : NSObject, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    let viewModel : PrompterViewModel
    let wordsCollection : UICollectionView
    
    init(viewModel: PrompterViewModel,
         wordsCollection: UICollectionView) {
        self.viewModel = viewModel
        self.wordsCollection = wordsCollection
        super.init()
        wordsCollection.delegate = self
        wordsCollection.dataSource = self
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let itemSide = collectionView.frame.width
        return CGSize(width: itemSide, height: itemSide)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.pagesNumber
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PrompterCollectionViewCell", for: indexPath) as! PrompterCollectionViewCell
        let text = viewModel.text(forIndex: indexPath.row)
        cell.setup(withText: text)
        return cell
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let itemWidth = scrollView.frame.width
        let itemNum = scrollView.contentOffset.x / itemWidth
        viewModel.currentPage = Int(itemNum)
    }

}
