//
//  RenderTask.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import Foundation


public typealias VisheoRenderTaskID = String;


public enum RenderQuality: Int
{
	case res480 = 480
	case res720 = 720
	case res1080 = 1080
}


public struct VisheoRenderTask: RealmConvertible
{
	typealias T = RLMVisheoRenderTask
	
	let cover: URL;
	let photos: [URL];
	let video: URL;
	let audio: URL;
	let id: VisheoRenderTaskID;
	let quality: RenderQuality;
	
	
	public init(id: VisheoRenderTaskID, cover: URL, photos: [URL], video: URL, audio: URL, quality: RenderQuality = .res480)
	{
		self.id = id;
		self.cover = cover;
		self.photos = photos;
		self.video = video;
		self.audio = audio;
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
	
	
	func encode() -> RLMVisheoRenderTask
	{
		let task = RLMVisheoRenderTask();
		
		task.id = id;
		task.cover = cover.path;
		task.photos.append(objectsIn: photos.map{ $0.path })
		task.video = video.path;
		task.audio = audio.path;
		task.quality = quality.rawValue;
		
		return task;
	}
	
	
	static func decode(from task: RLMVisheoRenderTask) -> VisheoRenderTask
	{
		return VisheoRenderTask(id: task.id,
		                        cover: URL(fileURLWithPath: task.cover),
		                        photos: task.photos.map{ URL(fileURLWithPath: $0) },
		                        video: URL(fileURLWithPath: task.cover),
		                        audio: URL(fileURLWithPath: task.cover),
		                        quality: RenderQuality(rawValue: task.quality) ?? .res480);
	}
}
