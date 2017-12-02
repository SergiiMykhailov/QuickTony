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
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        updateItemSize()
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        
        updateItemSize()
    }

    @IBOutlet weak var collectionView: UICollectionView!
    
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
