//
//  Migrations.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/15/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GRDB

struct Migrations
{
	static func migrate(in dbPool: DatabasePool)
	{
		var migrator = DatabaseMigrator();
		
		migrator.registerMigration("v1") { (db) in
			
			try db.create(table: RenderTask.databaseTableName, body: { (t) in
				t.column("id", .integer).primaryKey(onConflict: nil, autoincrement: true);
				t.column("quality", .integer);
			});
			
			try db.create(table: MediaUnit.databaseTableName, body: { (t) in
				t.column("id", .integer).primaryKey(onConflict: nil, autoincrement: true);
				t.column("task_id", .integer).references(RenderTask.databaseTableName, column: "id", onDelete: .cascade, onUpdate: .cascade, deferred: true);
				t.column("url", .text);
				t.column("type", .text);
				t.column("render_order", .integer);
			})
			
			try db.create(table: MotionTask.databaseTableName, body: { (t) in
				t.column("id", .integer).primaryKey(onConflict: nil, autoincrement: true);
				t.column("task_id", .integer).references(RenderTask.databaseTableName, column: "id", onDelete: .cascade, onUpdate: .cascade, deferred: true);
				t.column("media_id", .integer).references(MediaUnit.databaseTableName, column: "id", onDelete: .cascade, onUpdate: .cascade, deferred: true);
				t.column("output", .text);
				t.column("state", .integer);
				t.column("render_order", .integer);
			})
			
			try db.create(table: TransitionTask.databaseTableName, body: { (t) in
				t.column("id", .integer).primaryKey(onConflict: nil, autoincrement: true);
				t.column("task_id", .integer).references(RenderTask.databaseTableName, column: "id", onDelete: .cascade, onUpdate: .cascade, deferred: true);
				t.column("output", .text);
				t.column("state", .integer);
				t.column("render_order", .integer);
				
				t.column("from_motion_id", .integer).references(MotionTask.databaseTableName, column: "id", onDelete: .cascade, onUpdate: .cascade, deferred: true);
				t.column("from_motion_url", .text);
				t.column("from_motion_time_value", .integer);
				t.column("from_motion_time_scale", .integer);
				
				t.column("to_motion_id", .integer).references(MotionTask.databaseTableName, column: "id", onDelete: .cascade, onUpdate: .cascade, deferred: true);
				t.column("to_motion_url", .text);
				t.column("to_motion_time_value", .integer);
				t.column("to_motion_time_scale", .integer);
			})
		}
		
		try? migrator.migrate(dbPool)
	}
}

