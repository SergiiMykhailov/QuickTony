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


public final class VisheoRenderer
{
	let dbPool: DatabasePool;
	
	
	let extractor = VideoThumbnailExtractor();
	let renderer = VideoConvertibleRenderer();
	
	
	public init(dbPool: DatabasePool)
	{
		self.dbPool = dbPool
		LOTAnimationCache.shared().disableCaching();
	}
	
	
	public func render(task: RenderTask)
	{
		do
		{
			let types = [MediaType.cover, MediaType.photo].map{ $0.rawValue }
			let taskColumn = MediaUnit.column(for: .taskId);
			let typeColumn = MediaUnit.column(for: .type);
			let orderColumn = MediaUnit.column(for: .renderOrder);
			
			try dbPool.read { (db) in
				let units = try MediaUnit.filter( taskColumn == task.id && types.contains(typeColumn) )
										.order(orderColumn)
										.fetchAll(db);
				print("\(units)")
			}
		}
		catch (let error)
		{
			print("\(error)");
		}
		
		
		
		
//		self.start = CACurrentMediaTime()
//		
//		NotificationCenter.default.post(name: NSNotification.Name(rawValue: "start"), object: self, userInfo: nil)
//		
//		let paths = [task.cover] + task.photos;
//		
//		let group = DispatchGroup();
//		
//		var urls = [URL]()
//		
//		for (index, url) in paths.enumerated()
//		{
//			let exportURL = (documentsDirectory()?.appendingPathComponent("video_\(index).mp4"))!;
//			
//			try? FileManager.default.removeItem(at: url);
//			
//			let motion = MotionAnimation(asset: url, bounds: task.maxRenderSize, duration: 2.2);
//			
//			urls.append(url);
//			
//			group.enter();
//			_ = renderer.render(asset: motion, to: exportURL, completion: { _ in
//				group.leave();
//			})
//		}
//		
//		group.notify(queue: DispatchQueue.main) {
//			self.renderThumbnails(videos: urls, task: task);
//		}
	}
	
	
//	func renderThumbnails(videos: [URL], task: VisheoRenderTask)
//	{
//		let allVideos = videos + [ task.video ];
//
//		let assets = allVideos.map(AVURLAsset.init)
//
//		let group = DispatchGroup();
//
//		var urls = [URL]()
//		var res = [[VideoThumbnail]]()
//
//		for (index, asset) in assets.enumerated()
//		{
//			group.enter()
//
//			extractor.generateThumbnails(asset: asset, frames: [.first, .last], completion: { (results) in
//
//				guard let value = results.value else {
//					group.leave();
//					return;
//				}
//
//				res.append(value);
//
//				for result in value
//				{
//					var filename = "";
//
//					switch result.frame
//					{
//						case .first:
//							filename = "video_\(index)_first";
//						case .last:
//							filename = "video_\(index)_last";
//						default:
//							continue;
//					}
//
//					let url = (documentsDirectory()?.appendingPathComponent("\(filename).jpg"))!;
//
//					try? FileManager.default.removeItem(at: url);
//
//					try? UIImageJPEGRepresentation(result.image, 1.0)?.write(to: url);
//					urls.append(url);
//				}
//
//				group.leave();
//			})
//		}
//
//		group.notify(queue: DispatchQueue.main) {
//			self.renderTransitions(urls: urls, task: task);
//		}
//	}
//
//
//	func renderTransitions(urls: [URL], task: VisheoRenderTask)
//	{
//		let nn = Bundle.main.path(forResource: "data1", ofType: "json")!;
//		let url1 = URL.init(fileURLWithPath: nn);
//
//		let group = DispatchGroup();
//
//		for i in 0...5
//		{
//			let last = (documentsDirectory()?.appendingPathComponent("video_\(i)_last.jpg"))!
//			let first = (documentsDirectory()?.appendingPathComponent("video_\(i+1)_first.jpg"))!
//
//			let transition = LottieTransition(animation: url1, size: task.maxRenderSize, frames: [first, last]);
//
//			tasks.append(transition);
//
//			let url = (documentsDirectory()?.appendingPathComponent("transition_\(i).mp4"))!;
//
//			try? FileManager.default.removeItem(at: url);
//
//			group.enter()
//
//			renderer.render(asset: transition, to: url, completion: { [weak self] (res) in
//				group.leave();
//			})
//		}
//
//		group.notify(queue: DispatchQueue.main) {
//			self.stitch(task: task);
//		}
//	}
//
//
//	func stitch(task: VisheoRenderTask)
//	{
//		var urls = [URL]()
//
//		for i in 0...5
//		{
//			let video = (documentsDirectory()?.appendingPathComponent("video_\(i).mp4"))!;
//			let transition = (documentsDirectory()?.appendingPathComponent("transition_\(i).mp4"))!;
//
//			urls += [video, transition]
//		}
//
//		urls.append(task.video);
//
//		let composition = AVMutableComposition();
//
//		let videoTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
//
//		var time = kCMTimeZero;
//
//		let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack);
//
//		let audio = AVURLAsset(url: task.audio);
//		let videoSoundTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))!;
//		let musicTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))!;
//
//
//		for (index, url) in urls.enumerated()
//		{
//			let asset = AVURLAsset(url: url);
//			let track = asset.tracks(withMediaType: .video).first!;
//
//			try? videoTrack.insertTimeRange(track.timeRange, of: track, at: time);
//
////			let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track);
//			trackInstruction.setTransform(CGAffineTransform.identity, at: time);
//
//			if (!track.naturalSize.equalTo(task.renderSize))
//			{
//				let scale = task.renderSize.width / track.naturalSize.width;
//				let transform = CGAffineTransform(scaleX: scale, y: scale);
//				trackInstruction.setTransform(transform, at: time);
//			}
//
//			if (index == urls.count - 1) {
//				let audiot = asset.tracks(withMediaType: .audio).first!;
//				try? videoSoundTrack.insertTimeRange(track.timeRange, of: audiot, at: time);
//			}
//
//			time = CMTimeAdd(time, CMTimeSubtract(track.timeRange.end, track.minFrameDuration));
//		}
//
//		let track = audio.tracks(withMediaType: .audio).first!;
//		try? musicTrack.insertTimeRange(videoTrack.timeRange, of: track, at: kCMTimeZero);
//
//
//		let mainInstruction = AVMutableVideoCompositionInstruction();
//		mainInstruction.layerInstructions = [ trackInstruction ];
//		mainInstruction.timeRange = videoTrack.timeRange;
//
//		let videoComposition = AVMutableVideoComposition();
//
//		videoComposition.renderSize = task.renderSize;
//		videoComposition.instructions = [mainInstruction];
//		videoComposition.frameDuration = videoTrack.minFrameDuration;
//
//		let output = (documentsDirectory()?.appendingPathComponent("finalRes.mp4"))!;
//
//		try? FileManager.default.removeItem(at: output);
//
//		let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality);
//		
//		session?.outputURL = output;
//		session?.outputFileType = .mp4;
//		session?.videoComposition = videoComposition;
//
//		session?.exportAsynchronously { [unowned self] in
//			let end = CACurrentMediaTime();
//
//			let diff = end - self.start;
//
//			NotificationCenter.default.post(name: NSNotification.Name(rawValue: "finished"), object: self, userInfo: [ "time" : diff ])
//
//			print("Final export in \(diff) seconds  to \(String(describing: session?.error)) to \(output)");
//		}
//	}
}
