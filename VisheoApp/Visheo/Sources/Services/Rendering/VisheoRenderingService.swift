//
//  VisheoRenderingService.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/24/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import VisheoVideo


protocol RenderingService {
    func export(creationInfo: VisheoCreationInfo, progress: ((Double)->())?, completion: ((URL?,Error?)->())?)
}

class VisheoRenderingService : RenderingService {
    func export(creationInfo: VisheoCreationInfo, progress: ((Double)->())?, completion: ((URL?,Error?)->())?) {
        
        let seconds = 5.0
        for i in stride(from: 0, to: 1.0, by: 0.05) {
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + i * seconds, execute: {
                progress?(i)
            })
        }
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + seconds, execute: {
            completion?(creationInfo.videoUrl, nil)
        })
    }
}

//    func export(assets: VisheoRenderingAssets)
//    {
//        let audio = Bundle.main.path(forResource: "beginning", ofType: "m4a")!;
//
//        var task = RenderTask(quality: .res720);
//
//        task.addMedia(assets.coverUrl!, type: .cover);
//        task.addMedia(assets.photoUrls, type: .photo);
//        task.addMedia(assets.videoUrl, type: .video);
//        task.addMedia(URL(fileURLWithPath: audio), type: .audio);
//
//        RenderQueue.shared.enqueue(task);
//    }

