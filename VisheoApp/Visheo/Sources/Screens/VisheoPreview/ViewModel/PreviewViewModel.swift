//
//  PreviewViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import UIKit

protocol PreviewViewModel : class {
    func editCover()
    
    var coverImage : UIImage? {get}
}

class VisheoPreviewViewModel : PreviewViewModel {
    var coverImage: UIImage? {
        return UIImage(data: FileManager.default.contents(atPath: (assets.coverUrl?.path)!)!)
    }
    weak var router: PreviewRouter?
    let assets: VisheoRenderingAssets
    
    init(assets: VisheoRenderingAssets) {
        self.assets = assets
    }
    
    func editCover() {
        router?.showCoverEdit(with: assets)
    }
}
