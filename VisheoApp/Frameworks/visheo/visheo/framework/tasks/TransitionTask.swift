//
//  TransitionTask.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/19/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GRDB
import AVFoundation


struct TransitionTask: StatefulTask
{
	var state: TaskState;
	var taskId: Int64?;
	var id: Int64?;
	var output: URL? = nil;
	var renderOrder: Int;
	
	var fromMotionId: Int64?;
	var fromMotionFrame: URL?;
	var fromMotionFrameTime: CMTime? = nil;
	
	var toMotionId: Int64?;
	var toMotionFrame: URL?;
	var toMotionFrameTime: CMTime? = nil;
	
	
	init(from: Int64?, to: Int64?, taskId: Int64?, order: Int)
	{
		state = .blocked;
		
		self.taskId = taskId;
		self.renderOrder = order;
		self.fromMotionId = from;
		self.toMotionId = to;
	}
}


extension TransitionTask: Codable, RowConvertible, MutablePersistable
{
	static var databaseTableName: String {
		return "transition_tasks"
	}
	
	enum CodingKeys: String, CodingKey
	{
		case state
		case taskId = "task_id"
		case id
		case output
		case renderOrder = "render_order"
		
		case fromId = "from_motion_id"
		case fromURL = "from_motion_url"
		case fromTimeValue = "from_motion_time_value"
		case fromTimeScale = "from_motion_time_scale"
		
		case toId = "to_motion_id"
		case toURL = "to_motion_url"
		case toTimeValue = "to_motion_time_value"
		case toTimeScale = "to_motion_time_scale"
	}
	
	
	func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(state.rawValue, forKey: .state);
		try container.encode(taskId, forKey: .taskId);
		try container.encode(id, forKey: .id);
		try container.encode(output?.path, forKey: .output);
		try container.encode(renderOrder, forKey: .renderOrder)
		
		try container.encode(fromMotionId, forKey: .fromId);
		try container.encode(fromMotionFrame?.path, forKey: .fromURL);
		try container.encode(fromMotionFrameTime?.value, forKey: .fromTimeValue);
		try container.encode(fromMotionFrameTime?.timescale, forKey: .fromTimeScale);
		
		try container.encode(toMotionId, forKey: .toId);
		try container.encode(toMotionFrame?.path, forKey: .toURL);
		try container.encode(toMotionFrameTime?.value, forKey: .toTimeValue);
		try container.encode(toMotionFrameTime?.timescale, forKey: .toTimeScale);
	}
	
	
	init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		let rawState = try container.decode(Int.self, forKey: .state);
		state = TaskState(rawValue: rawState)!;
		
		id = try container.decodeIfPresent(Int64.self, forKey: .id);
		taskId = try container.decodeIfPresent(Int64.self, forKey: .taskId);
		renderOrder = try container.decode(Int.self, forKey: .renderOrder);
		
		let rawOutput = try container.decodeIfPresent(String.self, forKey: .output);
		
		if let _ = rawOutput {
			output = URL(fileURLWithPath: rawOutput!);
		}
		
		fromMotionId = try container.decodeIfPresent(Int64.self, forKey: .fromId);
		var rawURL = try container.decodeIfPresent(String.self, forKey: .fromURL)
		var value = try container.decodeIfPresent(CMTimeValue.self, forKey: .fromTimeValue);
		var timescale = try container.decodeIfPresent(CMTimeScale.self, forKey: .fromTimeScale);
		
		if let v = value, let t = timescale {
			fromMotionFrameTime = CMTime(value: v, timescale: t);
		}
		
		if let _ = rawURL {
			fromMotionFrame = URL(fileURLWithPath: rawURL!);
		}
		
		toMotionId = try container.decodeIfPresent(Int64.self, forKey: .toId);
		rawURL = try container.decodeIfPresent(String.self, forKey: .toURL)
		value = try container.decodeIfPresent(CMTimeValue.self, forKey: .toTimeValue);
		timescale = try container.decodeIfPresent(CMTimeScale.self, forKey: .toTimeScale);
		
		if let v = value, let t = timescale {
			toMotionFrameTime = CMTime(value: v, timescale: t);
		}
		
		if let _ = rawURL {
			toMotionFrame = URL(fileURLWithPath: rawURL!);
		}
	}
	
	
	mutating func didInsert(with rowID: Int64, for column: String?) {
		id = rowID;
	}
}
