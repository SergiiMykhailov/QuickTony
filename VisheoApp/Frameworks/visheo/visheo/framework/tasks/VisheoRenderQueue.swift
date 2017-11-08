//
//  VisheoRenderQueue.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import RealmSwift


public final class VisheoRenderQueue
{
	private lazy var renderer = VisheoRenderer();
	private let configuration: Realm.Configuration;
	
	
	public init()
	{
		configuration = Realm.Configuration(fileURL: VisheoRenderQueue.dbPath);
	}
	
	
	public func enqueue(task: VisheoRenderTask)
	{
		let dbTask = task.encode();
		
		do {
			let realm = try Realm(configuration: configuration);
			
			try realm.write {
				realm.add(dbTask, update: true);
			}
		}
		catch {
			
		}
	}
	
	
	static var dbPath: URL
	{
		let documentsPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!;
		var url = URL(fileURLWithPath: documentsPath);
		url.appendPathComponent("visheo.realm");
		return url;
	}
}
