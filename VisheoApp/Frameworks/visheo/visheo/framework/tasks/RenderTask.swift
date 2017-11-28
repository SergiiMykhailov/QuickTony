//
//  RenderTask.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Foundation
import GRDB


public struct RenderTask: StatefulTask
{
	var media: [MediaUnit] = [];
	var id: Int64?;
	var output: URL?;
	let quality: RenderQuality;
	var state: TaskState;
	
	public init(quality: RenderQuality = .res480) {
		self.quality = quality;
		self.state = .pending;
	}
	
	public mutating func addMedia(_ url: URL, type: MediaType) {
		let unit = MediaUnit(type: type, url: url);
		self.media.append(unit);
	}
	
	
	public mutating func addMedia(_ media: [URL], type: MediaType) {
		for (index, url) in media.enumerated() {
			let unit = MediaUnit(type: type, renderOrder: index, url: url);
			self.media.append(unit);
		}
	}
}


extension RenderTask: Codable, MutablePersistable, RowConvertible
{
	public static var databaseTableName: String {
		return "render_tasks"
	}
	
	enum CodingKeys: String, CodingKey
	{
		case id
		case quality
		case output
		case state
	}
	
	
	public init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		id = try container.decodeIfPresent(Int64.self, forKey: .id);
		
		let rawOutput = try container.decodeIfPresent(String.self, forKey: .output);
		if let _ = rawOutput {
			output = URL(fileURLWithPath: rawOutput!);
		}

		let rawQuality = try container.decode(Int.self, forKey: .quality)
		quality = RenderQuality(rawValue: rawQuality) ?? .res480;
		
		let rawState = try container.decode(Int.self, forKey: .state);
		state = TaskState(rawValue: rawState) ?? .pending;
	}
	
	
	public func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self);
		
		try container.encode(id, forKey: .id);
		try container.encode(quality.rawValue, forKey: .quality);
		try container.encode(output?.path, forKey: .output);
		try container.encode(state.rawValue, forKey: .state);
	}
	
	
	mutating public func didInsert(with rowID: Int64, for column: String?) {
		id = rowID
	}
}
