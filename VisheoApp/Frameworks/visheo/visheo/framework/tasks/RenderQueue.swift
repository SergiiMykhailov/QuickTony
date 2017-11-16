//
//  VisheoRenderQueue.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//


import GRDB


public final class RenderQueue
{
	private let pool: DatabasePool;
	
	private lazy var renderer = VisheoRenderer(dbPool: self.pool);
	
	
	public init()
	{
		pool = try! DatabasePool(path: RenderQueue.dbPath);
		Migrations.migrate(in: pool);
	}
	
	
	public func enqueue(_ task: RenderTask)
	{
		var task = task;
		
		do
		{
			try pool.writeInTransaction{ (db) in
				try task.save(db);
				
				for var media in task.media {
					media.taskId = task.id;
					try media.save(db);
				}
				
				return .commit;
			}
			
			renderer.render(task: task);
		}
		catch (let error) {
			print("\(error)")
		}
	}
	
	
	private static var dbPath: String
	{
		let url = try! FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("visheo_tasks.sqlite");
		
		print("\(url.path)")
		
		return url.path;
	}
}
