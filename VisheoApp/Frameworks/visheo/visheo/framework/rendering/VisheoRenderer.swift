//
//  VisheoRenderer.swift
//  visheo
//
//  Created by Nikita Ivanchikov on 11/2/17.
//  Copyright © 2017 Nikita Ivanchikov. All rights reserved.
//

import AVFoundation


public final class VisheoRenderer
{
	public init() {
		
	}
	
	public func render(task: VisheoRenderTask)
	{
		let coverImage = UIImage(contentsOfFile: task.cover.path)!;
		let motion = MotionAnimator(asset: coverImage, bounds: task.renderSize, duration: 2.2);
		
		var urls = [URL]()
		
		let url = (documentsDirectory()?.appendingPathComponent("video_0.mp4"))!;
		
		try? FileManager.default.removeItem(at: url);
		
		urls.append(url);
		
		let renderer = VideoConvertibleRenderer();
		
		let group = DispatchGroup();
		
		group.enter()

		renderer.render(asset: motion, to: url) { (result) in
			group.leave();
		}
		
		for (index, photo) in task.photos.enumerated()
		{
			let image = UIImage(contentsOfFile: photo.path)!;
			let motion = MotionAnimator(asset: image, bounds: task.renderSize, duration: 2.2);
			
			let url = (documentsDirectory()?.appendingPathComponent("video_\(index + 1).mp4"))!;
			
			try? FileManager.default.removeItem(at: url);
			
			urls.append(url);
			
			group.enter()
			
			renderer.render(asset: motion, to: url) { (result) in
				group.leave();
			}
		}
		
		group.notify(queue: DispatchQueue.main)
		{
			self.renderThumbnails(videos: urls, task: task);
		}
	}
	
	
	func renderThumbnails(videos: [URL], task: VisheoRenderTask)
	{
		let allVideos = videos + [ task.video ];
		
		let assets = allVideos.map(AVURLAsset.init)
		
		let group = DispatchGroup();
		
		var urls = [URL]()
		
		let extractor = VideoThumbnailExtractor();
		
		for (index, asset) in assets.enumerated()
		{
			group.enter()
			
			extractor.generateThumbnails(asset: asset, frames: [.first, .last], completion: { (results) in
				
				guard let value = results.value else {
					group.leave();
					return;
				}
				
				for result in value
				{
					var filename = "";
					
					switch result.frame
					{
						case .first:
							filename = "video_\(index)_first";
						case .last:
							filename = "video_\(index)_last";
						default:
							continue;
					}
					
					let url = (documentsDirectory()?.appendingPathComponent("\(filename).jpg"))!;
					
					try? FileManager.default.removeItem(at: url);
					
					try? UIImageJPEGRepresentation(result.image, 1.0)?.write(to: url);
					urls.append(url);
				}
				
				group.leave();
			})
		}
		
		group.notify(queue: DispatchQueue.main) {
			self.renderTransitions(urls: urls, task: task);
		}
	}
	
	
	func renderTransitions(urls: [URL], task: VisheoRenderTask)
	{
		let nn = Bundle.main.path(forResource: "data1", ofType: "json")!;
		let url1 = URL.init(fileURLWithPath: nn);
		
		let renderer = VideoConvertibleRenderer();
		let group = DispatchGroup();
		
		for i in 0...5
		{
			let last = (documentsDirectory()?.appendingPathComponent("video_\(i)_last.jpg"))!
			let first = (documentsDirectory()?.appendingPathComponent("video_\(i+1)_first.jpg"))!

			let transition = LottieTransition(animation: url1, size: task.renderSize, frames: [first, last]);
			
			let url = (documentsDirectory()?.appendingPathComponent("transition_\(i).mp4"))!;
			
			try? FileManager.default.removeItem(at: url);
			
			group.enter()
			
			renderer.render(asset: transition, to: url, completion: { (res) in
				group.leave();
			})
		}
		
		group.notify(queue: DispatchQueue.main) {
			self.stitch(task: task)
		}
	}
	
	
	func stitch(task: VisheoRenderTask)
	{
		var urls = [URL]()
		
		for i in 0...5
		{
			let video = (documentsDirectory()?.appendingPathComponent("video_\(i).mp4"))!;
			let transition = (documentsDirectory()?.appendingPathComponent("transition_\(i).mp4"))!;
			
			urls += [video, transition]
		}
		
		urls.append(task.video);
		
		let composition = AVMutableComposition();
		
		let videoTrack = (composition.addMutableTrack(withMediaType: .video, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		
		var time = kCMTimeZero;
		
		let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: videoTrack);
		
		let audio = AVURLAsset(url: task.audio);
		let videoSoundTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		let musicTrack = (composition.addMutableTrack(withMediaType: .audio, preferredTrackID: kCMPersistentTrackID_Invalid))!;
		
		
		for (index, url) in urls.enumerated()
		{
			let asset = AVURLAsset(url: url);
			let track = asset.tracks(withMediaType: .video).first!;
			
			try? videoTrack.insertTimeRange(track.timeRange, of: track, at: time);
			
//			let trackInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: track);
			trackInstruction.setTransform(CGAffineTransform.identity, at: time);
			
			if (!track.naturalSize.equalTo(task.renderSize))
			{
				let scale = task.renderSize.width / track.naturalSize.width;
				let transform = CGAffineTransform(scaleX: scale, y: scale);
				trackInstruction.setTransform(transform, at: time);
			}
			
			if (index == urls.count - 1) {
				let audiot = asset.tracks(withMediaType: .audio).first!;
				try? videoSoundTrack.insertTimeRange(track.timeRange, of: audiot, at: time);
			}
		
			time = CMTimeAdd(time, CMTimeSubtract(track.timeRange.end, track.minFrameDuration));
		}
		
		let track = audio.tracks(withMediaType: .audio).first!;
		try? musicTrack.insertTimeRange(videoTrack.timeRange, of: track, at: kCMTimeZero);
		
		
		let mainInstruction = AVMutableVideoCompositionInstruction();
		mainInstruction.layerInstructions = [ trackInstruction ];
		mainInstruction.timeRange = videoTrack.timeRange;
		
		let videoComposition = AVMutableVideoComposition();
		
		videoComposition.renderSize = task.renderSize;
		videoComposition.instructions = [mainInstruction];
		videoComposition.frameDuration = videoTrack.minFrameDuration;
		
		let output = (documentsDirectory()?.appendingPathComponent("finalRes.mp4"))!;
		
		try? FileManager.default.removeItem(at: output);
		
		let session = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality);
		
		session?.outputURL = output;
		session?.outputFileType = .mp4;
		session?.videoComposition = videoComposition;
		
		session?.exportAsynchronously {
			print("Final export \(String(describing: session?.error))");
		}
	}
}
