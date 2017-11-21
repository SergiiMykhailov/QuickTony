//
//  RenderDatabase.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/19/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GRDB


enum RenderDatabaseError: Error
{
	case error
}


protocol RenderDatabase: class {
	init() throws;
	
	func add(task: RenderTask, completion: ((Result<RenderTask>) -> Void)?)
	func fetchMediaUnits(_ type: [MediaType], for task: RenderTask, completion: ((Result<[MediaUnit]>) -> Void)?)
	
	func add(motion: MotionTask, completion: ((Result<MotionTask>) -> Void)?)
	func add(motions: [MotionTask], completion: ((Result<[MotionTask]>) -> Void)?)
	
	func add(transition: TransitionTask, completion: ((Result<TransitionTask>) -> Void)?)
	func add(transitions: [TransitionTask], completion: ((Result<[TransitionTask]>) -> Void)?)
	
	func fetchMedia(for motion: MotionTask, completion: ((Result<MediaUnit?>) -> Void)?)
	func fetchMotions(for transition: TransitionTask, completion: ((Result<(from: MotionTask, to: MotionTask)>) -> Void)?)
	
	func motions(for task: RenderTask, completion: ((Result<[MotionTask]>) -> Void)?)
	func transitions(for task: RenderTask, completion: ((Result<[TransitionTask]>) -> Void)?)
}


final class VisheoRenderDatabase: RenderDatabase
{
	private let pool: DatabasePool;
	private let queue = DispatchQueue(label: "com.visheo.renderDBQueue", qos: .default, attributes: .concurrent);
	
	
	init() throws {
		let url = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("visheo_tasks.sqlite");
		
		pool = try DatabasePool(path: url.path);
		
		Migrations.migrate(in: pool);
	}
	
	
	func add(task: RenderTask, completion: ((Result<RenderTask>) -> Void)? = nil) {
		queue.async {
			var task = task;
			
			do {
				try self.pool.writeInTransaction{ (db) in
					try task.save(db);
					
					for var media in task.media {
						media.taskId = task.id;
						try media.save(db);
					}
					
					return .commit;
				}
				
				completion?(.success(value: task))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func fetchMediaUnits(_ types: [MediaType], for task: RenderTask, completion: ((Result<[MediaUnit]>) -> Void)? = nil)
	{
		let rawTypes = types.map{ $0.rawValue }
		let taskColumn = MediaUnit.column(for: .taskId);
		let typeColumn = MediaUnit.column(for: .type);
		
		queue.async {
			do {
				var units: [MediaUnit] = [];
				try self.pool.read { (db) in
					units = try MediaUnit.filter( taskColumn == task.id && rawTypes.contains(typeColumn) )
										.fetchAll(db);
				}
				completion?(.success(value: units));
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func add(motion: MotionTask, completion: ((Result<MotionTask>) -> Void)?) {
		add(motions: [motion], completion: { (result) in
			switch result {
				case .failure(let error):
					completion?(.failure(error: error));
				case .success(let value) where value.count > 0:
					completion?(.success(value: value.first!))
				default:
					completion?(.failure(error: RenderDatabaseError.error));
			}
		})
	}
	
	func add(motions: [MotionTask], completion: ((Result<[MotionTask]>) -> Void)? = nil)
	{
		queue.async {
			do {
				var stored = [MotionTask]();
				
				try self.pool.writeInTransaction{ (db) in
					for var motion in motions {
						try motion.save(db);
						stored.append(motion);
					}
					return .commit;
				}
				
				completion?(.success(value: stored))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func add(transition: TransitionTask, completion: ((Result<TransitionTask>) -> Void)?) {
		add(transitions: [transition], completion: { (result) in
			switch result {
				case .failure(let error):
					completion?(.failure(error: error));
				case .success(let value) where value.count > 0:
					completion?(.success(value: value.first!))
				default:
					completion?(.failure(error: RenderDatabaseError.error));
			}
		})
	}
	
	func add(transitions: [TransitionTask], completion: ((Result<[TransitionTask]>) -> Void)?)
	{
		queue.async {
			do {
				var stored = [TransitionTask]();
				
				try self.pool.writeInTransaction{ (db) in
					for var transition in transitions {
						try transition.save(db);
						stored.append(transition);
					}
					return .commit;
				}
				
				completion?(.success(value: stored))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func fetchMedia(for motion: MotionTask, completion: ((Result<MediaUnit?>) -> Void)?)
	{
		queue.async {
			do {
				var unit: MediaUnit? = nil;
				
				let taskColumn = MediaUnit.column(for: .taskId);
				let idColumn = MediaUnit.column(for: .id);
				
				try self.pool.read{ (db) in
					unit = try MediaUnit.filter(idColumn == motion.mediaId && taskColumn == motion.taskId).fetchOne(db)
				}
				
				completion?(.success(value: unit))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func fetchMotions(for transition: TransitionTask, completion: ((Result<(from: MotionTask, to: MotionTask)>) -> Void)?)
	{
		queue.async {
			do {
				var fromMotion: MotionTask? = nil;
				var toMotion: MotionTask? = nil;
				
				let taskColumn = MediaUnit.column(for: .taskId);
				let idColumn = MediaUnit.column(for: .id);
				
				try self.pool.read{ (db) in
					fromMotion = try MotionTask.filter(idColumn == transition.fromMotionId && taskColumn == transition.taskId).fetchOne(db)
					toMotion = try MotionTask.filter(idColumn == transition.toMotionId && taskColumn == transition.taskId).fetchOne(db)
				}
				
				guard let from = fromMotion, let to = toMotion else {
					return;
				}
				
				let result = (from: from, to: to)
				completion?(.success(value: result))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func motions(for task: RenderTask, completion: ((Result<[MotionTask]>) -> Void)?) {
		queue.async {
			do {
				let taskColumn = MediaUnit.column(for: .taskId);
				var motions: [MotionTask] = [];
				
				try self.pool.read{ (db) in
					motions = try MotionTask.filter(taskColumn == task.id).fetchAll(db);
				}
				completion?(.success(value: motions))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func transitions(for task: RenderTask, completion: ((Result<[TransitionTask]>) -> Void)?) {
		queue.async {
			do {
				let taskColumn = MediaUnit.column(for: .taskId);
				var transitions: [TransitionTask] = [];
				
				try self.pool.read{ (db) in
					transitions = try TransitionTask.filter(taskColumn == task.id).fetchAll(db);
				}
				completion?(.success(value: transitions))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
}
