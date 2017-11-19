//
//  VideoTrimmingViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol VideoTrimmingViewModel : class {
    var videoUrl : URL {get}
}

class VisheoVideoTrimmingViewModel : VideoTrimmingViewModel {
    var videoUrl: URL {
        return assets.videoUrl
    }
    
    weak var router: VideoTrimmingRouter?
    let assets : VisheoRenderingAssets
    
    init(assets: VisheoRenderingAssets) {
        self.assets = assets
    }
}
