//
//  RenderTask.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Foundation
import GRDB


public enum RenderQuality: Int
{
	case res480 = 480
	case res720 = 720
	case res1080 = 1080
}


public struct RenderTask
{
	var media: [MediaUnit] = [];
	var id: Int64?;
	let quality: RenderQuality;
	
	
	public init(quality: RenderQuality = .res480)
	{
		self.quality = quality;
	}
	
	
	var renderSize: CGSize
	{
		return CGSize(width: quality.rawValue, height: quality.rawValue);
	}
	
	
	var maxRenderSize: CGSize
	{
		return CGSize(width: RenderQuality.res1080.rawValue, height: RenderQuality.res1080.rawValue);
	}
	
	
	public mutating func addMedia(_ url: URL, type: MediaType)
	{
		let unit = MediaUnit(type: type, url: url);
		self.media.append(unit);
	}
	
	
	public mutating func addMedia(_ media: [URL], type: MediaType)
	{
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
	}
	
	
	public init(from decoder: Decoder) throws
	{
		let container = try decoder.container(keyedBy: CodingKeys.self);
		
		id = try container.decode(Int64.self, forKey: .id);

		let rawQuality = try container.decode(Int.self, forKey: .quality)
		quality = RenderQuality(rawValue: rawQuality) ?? .res480;
	}
	
	
	public func encode(to encoder: Encoder) throws
	{
		var container = encoder.container(keyedBy: CodingKeys.self);
		
		try container.encode(id, forKey: .id);
		try container.encode(quality.rawValue, forKey: .quality);
	}
	
	
	mutating public func didInsert(with rowID: Int64, for column: String?) {
		id = rowID
	}
}
