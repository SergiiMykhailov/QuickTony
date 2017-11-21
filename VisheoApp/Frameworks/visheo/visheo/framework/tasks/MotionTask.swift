//
//  MotionTask.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/19/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GRDB

struct MotionTask: StatefulTask
{
	var state: TaskState;
	var taskId: Int64?;
	var mediaId: Int64?;
	var id: Int64?;
	var output: URL? = nil;
	var renderOrder: Int;
	var hasAudio: Bool;
	
	
	init(media: MediaUnit, taskId: Int64?, order: Int)
	{
		self.taskId = taskId;
		self.mediaId = media.id;
		self.renderOrder = order;
		
		if (media.type == .video) {
			state = .finished;
			output = media.url;
			hasAudio = true;
		} else {
			state = .pending;
			hasAudio = false;
		}
	}
}


extension MotionTask: Codable, RowConvertible, MutablePersistable
{
	static var databaseTableName: String {
		return "motion_tasks"
	}
	
	enum CodingKeys: String, CodingKey
	{
		case state
		case taskId = "task_id"
		case mediaId = "media_id"
		case id
		case output
		case renderOrder = "render_order"
        case hasAudio = "has_audio"
	}
	
	
	func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(state.rawValue, forKey: .state);
		try container.encode(taskId, forKey: .taskId);
		try container.encode(mediaId, forKey: .mediaId);
		try container.encode(id, forKey: .id);
		try container.encode(output?.path, forKey: .output);
		try container.encode(renderOrder, forKey: .renderOrder)
        try container.encode(hasAudio, forKey: .hasAudio);
	}
	
	
	init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		let rawState = try container.decode(Int.self, forKey: .state);
		state = TaskState(rawValue: rawState)!;
		
		id = try container.decodeIfPresent(Int64.self, forKey: .id);
		taskId = try container.decodeIfPresent(Int64.self, forKey: .taskId);
		mediaId = try container.decodeIfPresent(Int64.self, forKey: .mediaId);
		renderOrder = try container.decode(Int.self, forKey: .renderOrder);
        hasAudio = try container.decode(Bool.self, forKey: .hasAudio);
        
		let rawOutput = try container.decodeIfPresent(String.self, forKey: .output);
		if let _ = rawOutput {
			output = URL(fileURLWithPath: rawOutput!);
		}
	}
	
	
	mutating func didInsert(with rowID: Int64, for column: String?) {
		id = rowID;
	}
}
