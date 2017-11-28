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
	public static let shared = RenderQueue();
	
	private let database: RenderDatabase;
	private lazy var renderer = VisheoRenderer(db: self.database)
	private let settings: [AnimationSettings];
	
	
	public init(settings: [AnimationSettings] = []) {
		self.settings = settings;
		database = try! VisheoRenderDatabase();
	}
	
	
	public func enqueue(_ task: RenderTask, _ handler: ((Result<Int64>) -> Void)? = nil)
	{
		database.add(task: task) { result in
			switch result {
				case .success(let task):
					self.renderer.render(task: task, settings: self.settings);
					handler?(.success(value: task.id!));
				case .failure(let error):
					handler?(.failure(error: error));
			}
		}
	}
	
	
	public func restart(_ taskId: Int, _ handler: ((Result<Int64>) -> Void)? = nil)
	{
		let id = Int64(taskId);
		
		database.fetch(taskId: id) { result in
			switch result {
				case .success(let task):
					self.renderer.render(task: task, settings: self.settings);
					handler?(.success(value: id));
				case .failure(let error):
					handler?(.failure(error: error));
			}
		}
	}
}
