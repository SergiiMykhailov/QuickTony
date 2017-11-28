//
//  VisheoRenderer.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation
import Lottie
import GRDB
import PromiseKit


public enum VisheoRenderError: Error
{
	case unableToFinish
	case underlying(error: Error)
	case objectNotFound(id: Int64, type: Any.Type)
}


public extension Notification.Name
{
	static let renderTaskProgress = Notification.Name("taskRenderingProgress")
	static let renderTaskSucceeded = Notification.Name("renderTaskSucceeded")
	static let renderTaskFailed = Notification.Name("renderTaskFailed")
}


public extension Notification {
	enum RenderInfoKeys {
		case taskId
		case progress
		case output
		case error
	}
}


protocol FileURLRepresentable {
	var fileURL: URL? { get }
	var taskId: Int64? { get }
}


func renderOrder(lhs: MediaUnit, rhs: MediaUnit) -> Bool
{
	switch (lhs.type, rhs.type)
	{
		case (.cover, _):
			return true;
		case (_, .cover):
			return false;
		case (.video, _):
			return false;
		case (_, .video):
			return true;
		case (.photo, .photo):
			return lhs.renderOrder < rhs.renderOrder;
		default:
			return false;
	}
}


final class VisheoRenderer
{
	private unowned var db: RenderDatabase;
	private lazy var extractor = VideoThumbnailExtractor();
	private lazy var renderer = VideoConvertibleRenderer();
	
	init(db: RenderDatabase) {
		self.db = db
		LOTAnimationCache.shared().disableCaching();
	}
	
	
	private func generateSubtasks(for task: RenderTask) -> Promise<Void>
	{
		let timeline = PhotosTimelineTask(taskId: task.id!);
		return db.add(timelineTask: timeline).then{ _ in Void() }
	}
	
	
	func render(task: RenderTask)
	{
		var task = task;
		task.state = .running;
		
		self.post(progress: 0.0, for: Int(task.id!))
		
		firstly {
			generateSubtasks(for: task);
		}
		.then { [weak self] _ -> Promise<PhotosTimelineTask> in
			guard let `self` = self else { throw VisheoRenderError.unableToFinish }
			return self.db.fetchTimelineTasks(for: task).then{ $0.first! };
		}
		.then { [weak self] (timeline: PhotosTimelineTask) -> Promise<PhotosTimelineTask> in
			guard let `self` = self else { throw VisheoRenderError.unableToFinish }
			return self.render(timeline: timeline, task: task);
		}
		.then { [weak self] _ -> Promise<URL> in
			guard let `self` = self else { throw VisheoRenderError.unableToFinish }
			self.post(progress: 0.5, for: Int(task.id!))
			return self.stitch(task: task);
		}
		.then { url -> Promise<RenderTask> in
			task.output = url;
			task.state = .finished;
			return self.db.add(task: task);
		}
		.then { [weak self] task -> Void in
			self?.post(progress: 1.0, for: Int(task.id!));
			self?.postSuccess(for: task);
		}
		.recover { error -> Promise<Void> in
			task.state = .pending;
			return self.db.add(task: task).then { _ in throw error }
		}
		.catch { error in
			self.post(error: error, for: Int(task.id!));
		}
	}
	
	
	private func render(timeline: PhotosTimelineTask, task: RenderTask) -> Promise<PhotosTimelineTask>
	{
		if timeline.state == .finished {
			return Promise(value: timeline);
		}
		
		let url = try! generateURL(with: ".mp4", taskId: task.id!);
		
		var timeline = timeline;
		timeline.state = .running;
		
		let photos = db.fetchMediaUnits([.cover, .photo], for: task)
						.then { (units: [MediaUnit]) -> [URL] in
							units.sorted(by: renderOrder).map{ $0.url }
						}
		
		let video = db.fetchMediaUnits([.video], for: task)
						.then { (units: [MediaUnit]) -> Promise<ThumbnailFetchResult> in
							self.fetchSnapshot(from: units.first!, at: .first)
						}
		
		let fetchAssets = when(fulfilled: photos, video)
							.then { (res: ([URL], ThumbnailFetchResult)) -> [URL] in
								res.0 + [res.1.url]
							}
		
		return firstly {
			db.add(timelineTask: timeline);
		}
		.then { _ -> Promise<[URL]> in
			fetchAssets
		}
		.then { (urls: [URL]) -> Promise<Void> in
			let container = PhotosAnimation(frames: urls, quality: task.quality);
			return self.renderer.render(asset: container, to: url);
		}
		.then { _ -> Promise<PhotosTimelineTask> in
			timeline.output = url;
			timeline.state = .finished;
			return self.db.add(timelineTask: timeline);
		}
		.recover{ (e) -> Promise<PhotosTimelineTask> in
			timeline.state = .pending;
			return self.db.add(timelineTask: timeline).then { _ in throw e };
		}
	}

	func generateURL(with `extension`: String, taskId: Int64) throws -> URL
	{
		let filename = "\(UUID().uuidString)\(`extension`)";
		let folder = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true);
		var url = folder.appendingPathComponent("\(taskId)");
		
		if (!FileManager.default.fileExists(atPath: url.path)) {
			try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil);
		}
		
		url = url.appendingPathComponent(filename);
		return url;
	}
	
	typealias ThumbnailFetchResult = (url: URL, time: CMTime)
	
	
	func fetchSnapshot(from file: FileURLRepresentable, at frame: VideoAssetFrame) -> Promise<ThumbnailFetchResult>
	{
		return Promise { fl, rj in
			
			guard let url = file.fileURL else {
				rj(VideoConvertibleError.error);
				return;
			}
			
			let asset = AVURLAsset(url: url);
			
			extractor.generateThumbnails(asset: asset, frames: [frame], completion: { (result) in
				if case .failure(let error) = result {
					print("Failed to generate thumbnails for \(url)");
					rj(VisheoRenderError.underlying(error: error));
					return;
				}
				
				do
				{
					guard let thumbnail = result.value?.first else {
						return;
					}
					
					guard let imageData = UIImageJPEGRepresentation(thumbnail.image, 1.0) else {
						return;
					}
					
					let url = try self.generateURL(with: ".jpg", taskId: file.taskId!)
					
					try imageData.write(to: url, options: .atomic);
					
					fl((url, thumbnail.actualTime));
				}
				catch (let error) {
					rj(error);
				}
			});
		}
	}
	
	
	func stitch(task: RenderTask) -> Promise<URL>
	{
		let url = try! generateURL(with: ".mp4", taskId: task.id!);
		
		return firstly {
			when(fulfilled: db.fetchTimelineTasks(for: task), db.fetchMediaUnits([.video, .audio], for: task));
		}
		.then { (timeline, media) -> Promise<Void> in
			
			let audioURL = media.filter{ $0.type == .audio }.first?.url;
			let videoURL = media.filter{ $0.type == .video }.first?.url;
			let timelineURL = timeline.first?.output;
			
			guard let _ = audioURL, let _ = videoURL, let _ = timelineURL else {
				throw VideoConvertibleError.error;
			}
			
			let video = VisheoVideo(timeline: timelineURL!, video: videoURL!, audio: audioURL!, quality: task.quality);
			return self.renderer.render(asset: video, to: url);
		}
		.then {
			return Promise(value: url);
		}
	}
}


private extension VisheoRenderer
{
	func post(progress: Double, for taskId: Int) {
		let info : [ Notification.RenderInfoKeys : Any ] = [ Notification.RenderInfoKeys.taskId : taskId,
															 Notification.RenderInfoKeys.progress : progress ]
		NotificationCenter.default.post(name: Notification.Name.renderTaskProgress, object: self, userInfo: info);
	}
	
	func postSuccess(for task: RenderTask) {
		let info : [ Notification.RenderInfoKeys : Any ] = [ Notification.RenderInfoKeys.taskId : Int(task.id!),
															 Notification.RenderInfoKeys.output : task.output! ]
		NotificationCenter.default.post(name: Notification.Name.renderTaskSucceeded, object: self, userInfo: info);
	}
	
	func post(error: Error, for taskId: Int) {
		let info : [ Notification.RenderInfoKeys : Any ] = [ Notification.RenderInfoKeys.taskId : taskId,
															 Notification.RenderInfoKeys.error : error ]
		NotificationCenter.default.post(name: Notification.Name.renderTaskFailed, object: self, userInfo: info);
	}
}
