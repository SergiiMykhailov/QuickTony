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
	case objectNotFound(id: Int64, type: Any.Type)
}


protocol RenderDatabase: class {
	init() throws;
	
	func add(task: RenderTask, completion: ((Result<RenderTask>) -> Void)?)
	func fetch(taskId: Int64, completion: ((Result<RenderTask>) -> Void)?);
	
	func fetchMediaUnits(_ type: [MediaType], for task: RenderTask, completion: ((Result<[MediaUnit]>) -> Void)?)
	
	func add(timelineTask: PhotosTimelineTask, completion: ((Result<PhotosTimelineTask>) -> Void)?);
	func fetchTimelineTasks(for task: RenderTask, completion: ((Result<[PhotosTimelineTask]>) -> Void)?)
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
	
	
	func fetch(taskId: Int64, completion: ((Result<RenderTask>) -> Void)?)
	{
		let taskIdColumn = Column("id");
		
		queue.async {
			do {
				let maybeTask = try self.pool.read{ (db) -> RenderTask? in
									try RenderTask.filter( taskIdColumn == taskId ).fetchOne(db)
								}
				
				guard let task = maybeTask else {
					throw RenderDatabaseError.objectNotFound(id: taskId, type: RenderTask.self)
				}
				
				completion?(.success(value: task));
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
	
	func add(timelineTask: PhotosTimelineTask, completion: ((Result<PhotosTimelineTask>) -> Void)?)
	{
		queue.async {
			do {
				var stored = timelineTask;
				
				try self.pool.writeInTransaction{ (db) in
					try stored.save(db);
					return .commit;
				}
				
				completion?(.success(value: stored))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
	
	
	func fetchTimelineTasks(for task: RenderTask, completion: ((Result<[PhotosTimelineTask]>) -> Void)?)
	{
		queue.async {
			do {
				let taskColumn = PhotosTimelineTask.column(for: .taskId);
				var tasks: [PhotosTimelineTask] = [];
				
				try self.pool.read{ (db) in
					tasks = try PhotosTimelineTask.filter(taskColumn == task.id).fetchAll(db);
				}
				completion?(.success(value: tasks))
			}
			catch (let error) {
				completion?(.failure(error: error));
			}
		}
	}
}
