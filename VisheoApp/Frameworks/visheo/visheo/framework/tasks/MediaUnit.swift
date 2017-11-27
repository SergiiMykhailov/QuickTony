//
//  MediaUnit.swift
//  VisheoVideo
//
//  Created by Nikita Ivanchikov on 11/15/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import GRDB

public enum MediaType: String
{
	case photo
	case video
	case cover
	case audio
}


struct MediaUnit: FileURLRepresentable
{
	let type: MediaType;
	let renderOrder: Int;
	let url: URL;
	var id: Int64? = nil;
	var taskId: Int64? = nil;
	
	
	init(type: MediaType, renderOrder: Int = -1, url: URL)
	{
		self.type = type;
		self.renderOrder = renderOrder;
		self.url = url;
	}
	
	
	var fileURL: URL? {
		return url;
	}
}


extension MediaUnit: Codable, RowConvertible, MutablePersistable
{
	static func column(for key: MediaUnit.CodingKeys) -> Column {
		return Column(key.rawValue);
	}
	
	
	static var databaseTableName: String {
		return "media_units"
	}
	
	enum CodingKeys: String, CodingKey
	{
		case type
		case renderOrder = "render_order"
		case url
		case id
		case taskId = "task_id"
	}
	
	
	func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self)
		
		try container.encode(type.rawValue, forKey: .type);
		try container.encode(renderOrder, forKey: .renderOrder);
		try container.encode(url, forKey: .url);
		try container.encode(id, forKey: .id);
		try container.encode(taskId, forKey: .taskId)
	}
	
	
	init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		let rawType = try container.decode(String.self, forKey: .type);
		type = MediaType(rawValue: rawType)!;
		
		id = try container.decodeIfPresent(Int64.self, forKey: .id);
		taskId = try container.decodeIfPresent(Int64.self, forKey: .taskId);
		url = try container.decode(URL.self, forKey: .url);
		renderOrder = try container.decode(Int.self, forKey: .renderOrder);
	}
	
	
	mutating func didInsert(with rowID: Int64, for column: String?) {
		id = rowID;
	}
}
