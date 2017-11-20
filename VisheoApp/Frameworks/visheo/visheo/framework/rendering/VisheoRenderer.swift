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
		return firstly {
			db.fetchMediaUnits([.cover, .photo, .video], for: task)
		}
		.then { units -> Promise<[MotionTask]> in
			
			let sorted = units.sorted(by: renderOrder)
			let motions = sorted.enumerated().map{ MotionTask(media: $0.element, taskId: task.id, order: $0.offset) }
			return self.db.add(motions: motions);
		}
		.then { motions -> Promise<Void> in
			
			var transitions = [TransitionTask]();
			for i in 0..<motions.count-1 {
				let transition = TransitionTask(from: motions[i].id, to: motions[i+1].id, taskId: task.id, order: i);
				transitions.append(transition);
			}
			return self.db.add(transitions: transitions).then{ _ in Void() };
		}
	}
	
	
	func render(task: RenderTask)
	{
		let start = CACurrentMediaTime();
		
		generateSubtasks(for: task)
			.then {
				self.db.motions(for: task);
			}
			.then {
				self.render(motions: $0, task: task);
			}
			.then {
				self.db.transitions(for: task);
			}
			.then {
				self.render(transitions: $0, task: task)
			}
			.then {
				self.stitch(task: task);
			}
			.then {
				print("Rendered in \(CACurrentMediaTime() - start)");
			}
			.catch { error in
				print("Rendered \(error)");
			}
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
			let animation = MotionAnimation(asset: media!.url, bounds: task.maxRenderSize, duration: 2.2);
			return self.renderer.render(asset: animation, to: url);
		}
		.then { _ -> Promise<MotionTask> in
			motion.output = url;
			motion.state = .finished;
			return self.db.add(motion: motion)
		}
		.recover{ (e) -> Promise<MotionTask> in
			motion.state = .pending;
			return self.db.add(motion: motion)
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
			let animation = LottieTransition(animation: animationURL, size: task.maxRenderSize, frames: [transition.fromMotionFrame!, transition.toMotionFrame!])
			return self.renderer.render(asset: animation, to: url).then{ _ in transition };
		}
		.then { transition -> Promise<TransitionTask> in
			var transition = transition;
			transition.output = url;
			transition.state = .finished;
			return self.db.add(transition: transition)
		}
		.recover{ (e) -> Promise<TransitionTask> in
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
	
	func fetchSnapshot(from motion: MotionTask, at frame: VideoAssetFrame) -> Promise<ThumbnailFetchResult>
	{
		return Promise { fl, rj in
			
			guard let url = motion.output else {
				rj(VideoConvertibleError.error);
				return;
			}
			
			let asset = AVURLAsset(url: url);
			
			extractor.generateThumbnails(asset: asset, frames: [frame], completion: { (result) in
				if case .failure(let error) = result {
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
					
					let url = try self.generateURL(with: ".jpg", taskId: motion.taskId!)//folder.appendingPathComponent(filename);
					
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
			when(fulfilled: db.motions(for: task), db.transitions(for: task), db.fetchMediaUnits([.audio], for: task));
		}
		.then { (motions, transitions, audio) -> Promise<Void> in
			guard let audioURL = audio.first?.url, !motions.isEmpty, !transitions.isEmpty else {
				throw VideoConvertibleError.error;
			}
			let video = VisheoVideo(motions: motions, transitions: transitions, audio: audioURL, size: task.renderSize);
			return self.renderer.render(asset: video, to: url);
		}
	}
}
