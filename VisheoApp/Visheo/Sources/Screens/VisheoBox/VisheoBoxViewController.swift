//
//  VisheoBoxViewController.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 12/1/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

class VisheoBoxViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel.didChangeCallback = {[weak self] in
            self?.collectionView.reloadData()
            self?.emptyView.isHidden = self?.viewModel.visheosCount != 0
        }
        
        viewModel.didChangeAt = {[weak self] in
            self?.updateCell(at: $0)
        }
        
        self.emptyView.isHidden = self.viewModel.visheosCount != 0
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateItemSize()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        updateItemSize()
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var emptyView: UIView!
    
    //MARK: - VM+Router init
    
    private(set) var viewModel: VisheoBoxViewModel!
    private(set) var router: FlowRouter!
    
    func configure(viewModel: VisheoBoxViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    @IBAction func createPressed(_ sender: Any) {
        viewModel.showCreate()
    }
}

extension VisheoBoxViewController : UICollectionViewDelegate, UICollectionViewDataSource {
    
    func updateItemSize() {
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            let viewWidth = view.bounds.size.width
            let columns : CGFloat = 2
            let itemWidth = (viewWidth - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing) / columns
            
            let itemSize = CGSize(width: itemWidth, height: itemWidth + 21)
            layout.itemSize = itemSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.visheosCount
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "visheoCell", for: indexPath) as! VisheoCollectionViewCell
        let cellVm = viewModel.visheo(at: indexPath.row)
        cell.configure(with: cellVm)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        viewModel.select(visheo: indexPath.row)
    }
    
    func updateCell(at row: Int) {
        if let cell = collectionView.cellForItem(at: IndexPath(row: row, section: 0)) as? VisheoCollectionViewCell {
            let cellVm = viewModel.visheo(at: row)
            cell.configure(with: cellVm, animateProgress: true)
        }
    }
    
}

extension VisheoBoxViewController {
    //MARK: - Routing
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)
        router.prepare(for: segue, sender: sender)
    }
}
