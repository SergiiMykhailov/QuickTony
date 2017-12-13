//
//  SoundtracksService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/30/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import AVFoundation

enum SoundtracksServiceError: Error
{
	case missingDownloadURL(soundtrack: OccasionSoundtrack)
	case missingFileExtension(soundtrack: OccasionSoundtrack)
	case hasFaultyAudioFile(soundtrack: OccasionSoundtrack)
}


extension Notification.Name {
	static let soundtrackDownloadFailed = Notification.Name("soundtrackDownloadFailed");
	static let soundtrackDownloadFinished = Notification.Name("soundtrackDownloadFinished");
	static let soundtrackDownloadProgressed = Notification.Name("soundtrackDownloadProgressed");
}

enum SoundtracksServiceNotificationKeys: String {
	case trackId
	case downloadLocation
	case error
	case progress
}


protocol SoundtracksService: class {
	func playbackURL(for soundtrack: OccasionSoundtrack) -> URL?
	func cacheURL(for soundtrack: OccasionSoundtrack) -> URL?
	func soundtrackIsCached(soundtrack: OccasionSoundtrack) -> Bool;
	func download(_ soundtrack: OccasionSoundtrack);
	func cancelDownloads(except soundtrack: OccasionSoundtrack, completion: (() -> Void)?);
	func cancelAllDownloads();
}


class VisheoSoundtracksService: NSObject, SoundtracksService
{
	private let sessionConfiguration: URLSessionConfiguration;
	private let sessionQueue = OperationQueue();
	private lazy var filemanager = FileManager();
	private lazy var session: URLSession = {
		URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.sessionQueue);
	}()
	
	private var soundtracksCache: [OccasionSoundtrack] = [];
	
	init(configuration: URLSessionConfiguration = .default) {
		self.sessionConfiguration = configuration;
		super.init();
		
		
		cleanup();
	}
	
	func cleanup() {
		do {
			let folder = try soundtracksCacheFolder();
			let contents = try filemanager.contentsOfDirectory(at: folder, includingPropertiesForKeys: nil, options: FileManager.DirectoryEnumerationOptions.init(rawValue: 0))
			for url in contents {
				try filemanager.removeItem(at: url);
			}
		}
		catch {}
	}
	
	
	func playbackURL(for soundtrack: OccasionSoundtrack) -> URL? {
		if soundtrackIsCached(soundtrack: soundtrack) {
			return cacheURL(for: soundtrack);
		}
		return soundtrack.url;
	}
	
	func cacheURL(for soundtrack: OccasionSoundtrack) -> URL? {
		return try? _cacheURL(for: soundtrack)
	}
	
	func soundtrackIsCached(soundtrack: OccasionSoundtrack) -> Bool {
		guard let url = cacheURL(for: soundtrack) else {
			return false;
		}
		return filemanager.fileExists(atPath: url.path);
	}
	
	func download(_ soundtrack: OccasionSoundtrack)
	{
		let idx = soundtracksCache.index(where: { $0.id == soundtrack.id })
		if idx == nil {
			soundtracksCache.append(soundtrack);
		}
		
		if soundtrackIsCached(soundtrack: soundtrack) {
			return;
		}
		
		let taskDescription = "\(soundtrack.id)";
		
		session.getAllTasks { [weak self] tasks in
			
			if let task = tasks.filter({ $0.taskDescription == taskDescription }).first {
				switch task.state {
					case .running:
						return;
					default:
						break;
				}
			}

			let task = self?.session.downloadTask(with: soundtrack.url!);
			task?.taskDescription = taskDescription
			task?.resume();
		}
	}
	
	func cancelDownloads(except soundtrack: OccasionSoundtrack, completion: (() -> Void)?) {
		let taskDescription = "\(soundtrack.id)";
		
		session.getAllTasks { (tasks) in
			tasks.filter{ $0.taskDescription != taskDescription }.forEach{ $0.cancel() }
			completion?()
		}
	}
	
	func cancelAllDownloads() {
		session.getAllTasks { (tasks) in
			tasks.forEach{ $0.cancel() }
		}
	}
	
	// MARK: - Private
	private func _cacheURL(for soundtrack: OccasionSoundtrack) throws -> URL
	{
		guard let downloadURL = soundtrack.url else {
			throw SoundtracksServiceError.missingDownloadURL(soundtrack: soundtrack);
		}
		
		let pathExtension = downloadURL.pathExtension;
		
		guard !pathExtension.isEmpty else {
			throw SoundtracksServiceError.missingFileExtension(soundtrack: soundtrack);
		}
		
		var url = try soundtracksCacheFolder();
		url = url.appendingPathComponent("\(soundtrack.id)");
		url = url.appendingPathExtension(pathExtension);
		return url;
	}
	
	private func soundtracksCacheFolder() throws -> URL {
		var url = try filemanager.url(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true);
		url = url.appendingPathComponent("soundtracks")
		try filemanager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil);
		return url;
	}
	
	
	private func moveToCache(source: URL, soundtrack: OccasionSoundtrack) {
		do
		{
			let url = try _cacheURL(for: soundtrack);
			_ = try filemanager.replaceItemAt(url, withItemAt: source, backupItemName: nil, options: .usingNewMetadataOnly);
			
			let asset = AVURLAsset(url: url);
			
			guard let _ = asset.tracks(withMediaType: .audio).first else {
				try? filemanager.removeItem(at: url);
				throw SoundtracksServiceError.hasFaultyAudioFile(soundtrack: soundtrack);
			}
			
			let info: [ SoundtracksServiceNotificationKeys : Any ] = [ .trackId : soundtrack.id,
																	   .downloadLocation : url ]
			NotificationCenter.default.post(name: .soundtrackDownloadFinished, object: self, userInfo: info);
			
		} catch (let error) {
			let info: [ SoundtracksServiceNotificationKeys : Any ] = [ .trackId : soundtrack.id,
																	   .error : error ]
			NotificationCenter.default.post(name: .soundtrackDownloadFailed, object: self, userInfo: info);
		}
	}
	
	private func resumeData(for trackId: Int) -> Data? {
		return nil;
	}
}

extension VisheoSoundtracksService: URLSessionDownloadDelegate
{
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL)
	{
		guard let trackId = downloadTask.taskDescription.flatMap({ Int($0) }) else {
			return;
		}
		
		guard let idx = soundtracksCache.index(where: { $0.id == trackId }) else {
			return;
		}
		
		let soundtrack = soundtracksCache[idx];
		soundtracksCache.remove(at: idx);
		
		moveToCache(source: location, soundtrack: soundtrack);
	}
	
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		guard let trackId = task.taskDescription.flatMap({ Int($0) }), let e = error else {
			return;
		}
		
		if let idx = soundtracksCache.index(where: { $0.id == trackId }) {
			soundtracksCache.remove(at: idx);
		}
		
		let info: [ SoundtracksServiceNotificationKeys : Any ] = [ .trackId : trackId,
																   .error : e ]
		NotificationCenter.default.post(name: .soundtrackDownloadFailed, object: self, userInfo: info);
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		guard let trackId = downloadTask.taskDescription.flatMap({ Int($0) }) else {
			return;
		}
		
		let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite);
		let info: [SoundtracksServiceNotificationKeys : Any ] = [ .progress : progress,
																  .trackId : trackId ]
		
		NotificationCenter.default.post(name: .soundtrackDownloadProgressed, object: self, userInfo: info);
	}
}
