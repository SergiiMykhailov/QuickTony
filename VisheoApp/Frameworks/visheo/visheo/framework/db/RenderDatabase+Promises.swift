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
	
	func add(motion: MotionTask) -> Promise<MotionTask> {
		return Promise { fl, rj in
			add(motion: motion, completion: { result in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	func add(motions: [MotionTask]) -> Promise<[MotionTask]> {
		return Promise { fl, rj in
			add(motions: motions, completion: { result in
				switch result {
					case .success(let value):
						fl(value);
					case .failure(let error):
						rj(error);
				}
			})
		}
	}
	
	
	func add(transition: TransitionTask) -> Promise<TransitionTask> {
		return Promise { fl, rj in
			add(transition: transition, completion: { result in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	func add(transitions: [TransitionTask]) -> Promise<[TransitionTask]> {
		return Promise { fl, rj in
			add(transitions: transitions, completion: { result in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	
	func fetchMedia(for motion: MotionTask) -> Promise<MediaUnit?> {
		return Promise { fl, rj in
			fetchMedia(for: motion, completion: { (result) in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	
	func fetchMotions(for transition: TransitionTask) -> Promise<(from: MotionTask, to: MotionTask)>
	{
		return Promise { fl, rj in
			fetchMotions(for: transition, completion: { (result) in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	func motions(for task: RenderTask) -> Promise<[MotionTask]> {
		return Promise { fl, rj in
			motions(for: task, completion: { (result) in
				switch result {
				case .success(let value):
					fl(value);
				case .failure(let error):
					rj(error);
				}
			})
		}
	}
	
	
	func transitions(for task: RenderTask) -> Promise<[TransitionTask]> {
		return Promise { fl, rj in
			transitions(for: task, completion: { (result) in
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
