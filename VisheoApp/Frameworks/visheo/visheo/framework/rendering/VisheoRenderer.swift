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
		let start = CACurrentMediaTime();
		
		firstly {
			generateSubtasks(for: task);
		}
		.then { _ -> Promise<PhotosTimelineTask> in
			self.db.fetchTimelineTasks(for: task).then{ $0.first! };
		}
		.then { (timeline: PhotosTimelineTask) -> Promise<PhotosTimelineTask> in
			self.render(timeline: timeline, task: task);
		}
		.then { _ in
			self.stitch(task: task);
		}
		.then {
			print("Rendered in \(CACurrentMediaTime() - start)");
		}
		.catch { error in
			print("Rendered \(error)");
		}
	
		
//		let url = try! generateURL(with: ".mp4", taskId: task.id!);
//
//		firstly {
//			db.fetchMediaUnits([.video], for: task).then{ $0.first! }
//		}
//		.then {
//			self.fetchSnapshot(from: $0, at: .first)
//		}
//		.then{ result -> Promise<([MediaUnit], ThumbnailFetchResult)> in
//			self.db.fetchMediaUnits([.cover, .photo], for: task).then { ($0, result) }
//		}
//		.then { res -> Promise<Void> in
//			var sorted = res.0.sorted(by: renderOrder).map{ $0.url }
//			sorted.append(res.1.url);
//			let container = Container(frames: sorted, size: task.renderSize);
//			return self.renderer.render(asset: container, to: url);
//		}
////		.then { units -> Promise<Void> in
////			let sorted = units.sorted(by: renderOrder).map{ $0.url }
//
////		}
//		.then {
//			print("Rendered transitions in \(CACurrentMediaTime() - start)");
//		}
		
//		generateSubtasks(for: task)
//			.then {
//				self.db.motions(for: task);
//			}
//			.then {
//				self.render(motions: $0, task: task);
//			}
//			.then {
//				self.db.transitions(for: task);
//			}
//			.then {
//				self.render(transitions: $0, task: task)
//			}
//			.then {
//				print("Rendered transitions in \(CACurrentMediaTime() - start)");
//				return self.stitch(task: task);
//			}
//			.then {
//				print("Rendered in \(CACurrentMediaTime() - start)");
//			}
//			.catch { error in
//				print("Rendered \(error)");
//			}
	}
	
	
	private func finishedRendering(motion: MotionTask, task: RenderTask)
	{
		
	}
	
	
	private func render(motions: [MotionTask], task: RenderTask) -> Promise<Void>
	{
		var promises = [Promise<Void>]();
		
		for motion in motions
		{
			let promise = render(motion: motion, task: task)
							.then { result in
								self.finishedRendering(motion: result, task: task);
							}
			
			promises.append(promise);
		}
		
		return when(fulfilled: promises)
	}
	
	
	private func render(transitions: [TransitionTask], task: RenderTask) -> Promise<Void>
	{
		var promises = [Promise<Void>]();
		
		for transition in transitions
		{
			let promise = render(transition: transition, task: task)
								.then { result in
									Void()
								}
			promises.append(promise);
		}
		
		return when(fulfilled: promises)
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
			let container = Container(frames: urls, size: task.renderSize);
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
	
	
	private func render(motion: MotionTask, task: RenderTask) -> Promise<MotionTask>
	{
		if motion.state == .finished {
			return Promise(value: motion);
		}
		
		let url = try! generateURL(with: ".mp4", taskId: task.id!);
		
		var motion = motion;
		motion.state = .running;
		
		return firstly{
			db.add(motion: motion)
		}
		.then { _ in
			self.db.fetchMedia(for: motion)
		}
		.then { media -> Promise<Void> in
			let animation = MotionAnimation(asset: media!.url, bounds: task.renderSize, duration: 2.2);
			return self.renderer.render(asset: animation, to: url);
		}
		.then { _ -> Promise<MotionTask> in
			motion.output = url;
			motion.state = .finished;
			return self.db.add(motion: motion)
		}
		.recover{ (e) -> Promise<MotionTask> in
			motion.state = .pending;
			return self.db.add(motion: motion).then { _ in throw e }
		}
	}
	
	
	func render(transition: TransitionTask, task: RenderTask) -> Promise<TransitionTask>
	{
		if transition.state == .finished {
			return Promise(value: transition);
		}
		
		let url = try! generateURL(with: ".mp4", taskId: task.id!);
		
		let nn = Bundle.main.path(forResource: "data3", ofType: "json")!;
		let animationURL = URL(fileURLWithPath: nn);
		
		var transition = transition;
		transition.state = .running;
		
		return firstly{
			db.add(transition: transition)
		}
		.then { transition -> Promise<TransitionTask> in
			guard let _ = transition.fromMotionFrame, let _ = transition.toMotionFrame else {
				return self.fetchSnapshots(for: transition);
			}
			return Promise(value: transition);
		}
		.then { transition -> Promise<TransitionTask> in
			let frames = [transition.fromMotionFrame!, transition.toMotionFrame!]
			let animation = NativeAnimation(frames: frames, size: task.renderSize, duration: 2.2);
//			let animation = LottieFrameTransition(animation: animationURL, size: task.renderSize, frames: frames)
			return self.renderer.render(asset: animation, to: url).then{ _ in transition };
		}
		.then { transition -> Promise<TransitionTask> in
			var transition = transition;
			transition.output = url;
			transition.state = .finished;
			return self.db.add(transition: transition)
		}
		.recover{ (e) -> Promise<TransitionTask> in
			print("Failed to render transition \(e) - \(transition)")
			transition.state = .pending;
			return self.db.add(transition: transition)
		}
	}
	
	
	func fetchSnapshots(for transition: TransitionTask) -> Promise<TransitionTask>
	{
		var transition = transition;
		
		return firstly {
			db.fetchMotions(for: transition)
		}
		.then { motions -> Promise<(ThumbnailFetchResult, ThumbnailFetchResult)> in
			let first = self.fetchSnapshot(from: motions.from, at: .last);
			let last = self.fetchSnapshot(from: motions.to, at: .first);
			return when(fulfilled: first, last)
		}
		.then { results -> TransitionTask in
			transition.fromMotionFrameTime = results.0.time;
			transition.fromMotionFrame = results.0.url;
			transition.toMotionFrameTime = results.1.time;
			transition.toMotionFrame = results.1.url;
			return transition;
		}
		.then { transition in
			return self.db.add(transition: transition);
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
			
			let track = asset.tracks(withMediaType: .video).first!;
			
			let frame1 = VideoAssetFrame.time(CMTime(value: 1, timescale: CMTimeScale(track.nominalFrameRate)));
			
			extractor.generateThumbnails(asset: asset, frames: [frame, frame1], completion: { (result) in
				if case .failure(let error) = result {
					print("Failed to generate thumbnails for \(url)");
					rj(error);
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
					
					let url = try self.generateURL(with: ".jpg", taskId: file.taskId!)//folder.appendingPathComponent(filename);
					
					try imageData.write(to: url, options: .atomic);
					
					fl((url, thumbnail.actualTime));
				}
				catch (let error) {
					rj(error);
				}
			});
		}
	}
	
	
	func stitch(task: RenderTask) -> Promise<Void>
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
			
			let video = VisheoVideo(timeline: timelineURL!, video: videoURL!, audio: audioURL!, size: task.renderSize);
			return self.renderer.render(asset: video, to: url);
		}
	}
}
