//
//  RenderDatabase+Promises.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/20/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import PromiseKit

extension RenderDatabase
{
	func add(task: RenderTask) -> Promise<RenderTask> {
		return Promise { fl, rj in
			add(task: task, completion: { (result) in
				switch result {
					case .success(let value):
						fl(value);
					case .failure(let error):
						rj(error);
				}
			})
		}
	}
	
	func fetchMediaUnits(_ type: [MediaType], for task: RenderTask) -> Promise<[MediaUnit]> {
		return Promise { fl, rj in
			fetchMediaUnits(type, for: task, completion: { (result) in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	
	func add(timelineTask: PhotosTimelineTask) -> Promise<PhotosTimelineTask>
	{
		return Promise { fl, rj in
			add(timelineTask: timelineTask, completion: { result in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	
	func fetchTimelineTasks(for task: RenderTask) -> Promise<[PhotosTimelineTask]>
	{
		return Promise { fl, rj in
			fetchTimelineTasks(for: task, completion: { (result) in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
}
