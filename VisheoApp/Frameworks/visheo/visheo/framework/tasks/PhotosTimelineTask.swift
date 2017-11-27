//
//  PhotosTimelineTask.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/23/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GRDB

struct PhotosTimelineTask: StatefulTask
{
	var state: TaskState;
	var id: Int64?;
	var taskId: Int64;
	var output: URL?;
	
	
	init(taskId: Int64)
	{
		self.taskId = taskId;
		self.state = .pending;
	}
}

extension PhotosTimelineTask: Codable, RowConvertible, MutablePersistable
{
	static func column(for key: PhotosTimelineTask.CodingKeys) -> Column {
		return Column(key.rawValue);
	}
	
	static var databaseTableName: String {
		return "timeline_tasks"
	}
	
	
	enum CodingKeys: String, CodingKey
	{
		case state
		case taskId = "task_id"
		case id
		case output
	}
	
	
	func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(state.rawValue, forKey: .state);
		try container.encode(taskId, forKey: .taskId);
		try container.encode(id, forKey: .id);
		try container.encode(output?.path, forKey: .output);
	}
	
	
	init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		let rawState = try container.decode(Int.self, forKey: .state);
		state = TaskState(rawValue: rawState) ?? .pending;
		
		id = try container.decodeIfPresent(Int64.self, forKey: .id);
		taskId = try container.decode(Int64.self, forKey: .taskId);
		
		let rawOutput = try container.decodeIfPresent(String.self, forKey: .output);
		if let _ = rawOutput {
			output = URL(fileURLWithPath: rawOutput!);
		}
	}
	
	mutating func didInsert(with rowID: Int64, for column: String?) {
		id = rowID;
	}
}

