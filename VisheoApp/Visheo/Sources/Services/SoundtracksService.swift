//
//  SoundtracksService.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/30/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol SoundtracksService: class {
	func playbackURL(for soundtrack: OccasionSoundtrack) -> URL?
	func cacheURL(for soundtrackId: Int) -> URL?
	func soundtrackIsCached(id: Int) -> Bool;
	func download(_ soundtrack: OccasionSoundtrack);
}


class VisheoSoundtracksService: NSObject, SoundtracksService
{
	private let sessionConfiguration: URLSessionConfiguration;
	private let sessionQueue = OperationQueue();
	private lazy var filemanager = FileManager();
	private lazy var session: URLSession = {
		URLSession(configuration: self.sessionConfiguration, delegate: self, delegateQueue: self.sessionQueue);
	}()
	
	
	init(configuration: URLSessionConfiguration = .default) {
		self.sessionConfiguration = configuration;
		super.init();
	}
	
	func playbackURL(for soundtrack: OccasionSoundtrack) -> URL? {
		if soundtrackIsCached(id: soundtrack.id) {
			return cacheURL(for: soundtrack.id);
		}
		
		return soundtrack.url;
	}
	
	func cacheURL(for soundtrackId: Int) -> URL? {
		do {
			var url = try filemanager.url(for: FileManager.SearchPathDirectory.cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true);
			url = url.appendingPathComponent("soundtracks")
			try filemanager.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil);
			url = url.appendingPathComponent("\(soundtrackId)");
			return url;
		} catch {
			return nil;
		}
	}
	
	func soundtrackIsCached(id: Int) -> Bool {
		guard let url = cacheURL(for: id) else {
			return false;
		}
		return filemanager.fileExists(atPath: url.path);
	}
	
	func download(_ soundtrack: OccasionSoundtrack)
	{
		if soundtrackIsCached(id: soundtrack.id) {
			return;
		}
		
		let taskDescription = "\(soundtrack.id)";
		
		session.getAllTasks { [weak self] tasks in
			
			if let task = tasks.filter({ $0.taskDescription == taskDescription }).first {
				switch task.state {
					case .running,
						 .completed:
						return;
					default:
						break;
				}
			}
			
			guard let `self` = self else { return }
			
			var task: URLSessionDownloadTask;
			
			if let resumeData = self.resumeData(for: soundtrack.id) {
				task = self.session.downloadTask(withResumeData: resumeData);
			} else {
				task = self.session.downloadTask(with: soundtrack.url!);
			}
			
			task.taskDescription = taskDescription
			task.resume();
		}
	}
	
	
	// MARK: - Private
	private func resumeData(for trackId: Int) -> Data? {
		return nil;
	}
}

extension VisheoSoundtracksService: URLSessionDelegate, URLSessionDownloadDelegate
{
	func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
		if let userInfo = (error as NSError?)?.userInfo, let resumeData = userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
			print("\(resumeData)");
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
		do {
			guard let trackId = downloadTask.taskDescription.flatMap({ Int($0) }) else {
				return;
			}
			
			if let url = cacheURL(for: trackId) {
				_ = try filemanager.replaceItemAt(url, withItemAt: location, backupItemName: nil, options: .usingNewMetadataOnly);
			}
		} catch (let error) {
			
		}
	}
	
	func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
		
	}
}
