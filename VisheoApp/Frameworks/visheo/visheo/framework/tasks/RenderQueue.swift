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
	private let database: RenderDatabase;
	private lazy var renderer = VisheoRenderer(db: self.database)
	
	
	public init() {
		database = try! VisheoRenderDatabase();
	}
	
	
	public func enqueue(_ task: RenderTask)
	{
		database.add(task: task) { result in
			switch result {
				case .success(let task):
					self.renderer.render(task: task);
				default:
					break;
			}
		}
	}
	
	
	
}
