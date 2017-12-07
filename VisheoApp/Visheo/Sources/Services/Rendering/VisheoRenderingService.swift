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
	
	private let renderQueue: RenderQueue;
	
	init(appStateService: AppStateService) {
		let animationSettings = appStateService.appSettings.animationSettings;
		renderQueue = RenderQueue(settings: animationSettings);
	}
	
    func export(creationInfo: VisheoCreationInfo, progress: ((Double)->())?, completion: ((URL?,Error?)->())?) {
        
        var task = RenderTask(quality: creationInfo.premium ? .res720 : .res480);

        task.addMedia(creationInfo.coverUrl, type: .cover);
        task.addMedia(creationInfo.photoUrls, type: .photo);
        task.addMedia(creationInfo.videoUrl, type: .video);
        
        if let soundtrack = creationInfo.soundtrackUrl {
            task.addMedia(soundtrack, type: .audio);
		} else if creationInfo.soundtrackId > -1 { // the soundtrack was selected but no url - fallback to pre-bundled music
            let audio = Bundle.main.path(forResource: "beginning", ofType: "m4a")!;
            task.addMedia(URL(fileURLWithPath: audio), type: .audio);
        }

        renderQueue.enqueue(task) { result in
            if case .failure(let error) = result {
                completion?(nil, error)
            }
            
            if case .success(let currentTaskId) = result {
                NotificationCenter.default.addObserver(forName: Notification.Name.renderTaskProgress, object: nil, queue: OperationQueue.main) {(notification) in
                    guard let info = notification.userInfo,
                        let progressNumber = info[Notification.RenderInfoKeys.progress] as? Double,
                        let taskId = info[Notification.RenderInfoKeys.taskId] as? Int,
                         currentTaskId == taskId else {return}
                    
                    progress?(progressNumber)
                }
                
                NotificationCenter.default.addObserver(forName: Notification.Name.renderTaskFailed, object: nil, queue: .main) {(notification) in
                    guard let info = notification.userInfo,
                        let taskId = info[Notification.RenderInfoKeys.taskId] as? Int,
                         currentTaskId == taskId  else {return}
                    completion?(nil, info[Notification.RenderInfoKeys.error ] as? Error)
                }
                
                NotificationCenter.default.addObserver(forName: Notification.Name.renderTaskSucceeded, object: nil, queue: .main) {(notification) in
                    guard let info = notification.userInfo,
                        let taskId = info[Notification.RenderInfoKeys.taskId] as? Int,
                         currentTaskId == taskId else {return}
                    
                    completion?(info[Notification.RenderInfoKeys.output] as? URL,nil)
                }
            }
        }
    }
}
