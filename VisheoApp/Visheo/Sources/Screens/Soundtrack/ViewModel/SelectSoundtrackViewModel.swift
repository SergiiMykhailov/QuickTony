//
//  SelectSoundtrackViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation
import PromiseKit
import VisheoVideo

enum SoundtrackDownloadState
{
	case none
	case downloading(progress: Double)
	case done
	case failed
}


protocol SelectSoundtrackViewModel: class {
	var soundtracksCount: Int { get }
	func soundtrackCellModel(at index: Int) -> SoundtrackCellModel
	func selectSoundtrack(at index: Int);
	func statusText(for state: SoundtrackDownloadState) -> String?
	
	func cancelSelection()
	func confirmSelection()
	var canConfirmSelection: Bool { get }
	
	var bufferProgressChanged: ((_ indexPath: IndexPath?) -> Void)? { get set }
	var downloadStateChanged: ((SoundtrackDownloadState) -> Void)? { get set }
	var selectionChanged: (() -> Void)? { get set }
}


class VisheoSelectSoundtrackViewModel: NSObject, SelectSoundtrackViewModel
{
	private enum AssetKVOKeys: String {
		case timeRanges = "loadedTimeRanges";
		case duration = "duration"
		case status = "status"
		static let allKeys: [AssetKVOKeys] = [.timeRanges, .duration, .status]
	}
	
	private enum PlayerKVOKeys: String {
		case status = "status"
		static let allKeys: [PlayerKVOKeys] = [.status]
	}
	
	private enum BufferState {
		case none
		case monitoring(id: Int, progress: Double);
	}
	
	private enum PlaybackState {
		case fine
		case failed(error: Error)
	}
	
	
	weak var router: SelectSoundtrackRouter?
	let occasion : OccasionRecord
	let soundtracksService : SoundtracksService
	private let loggingService: EventLoggingService;
	let assets: VisheoRenderingAssets
	
	private lazy var player = AVPlayer();
	
	private var selectedSoundtrackId: Int? = nil {
		didSet {
			selectionChanged?()
		}
	}
	
	var bufferProgressChanged: ((_ indexPath: IndexPath?) -> Void)? = nil;
	var downloadStateChanged: ((SoundtrackDownloadState) -> Void)? = nil;
	var selectionChanged: (() -> Void)? = nil;
	private var observers: [ Notification.Name : Any ] = [:]
	
	private var playerItem: AVPlayerItem? = nil {
		willSet {
			for key in AssetKVOKeys.allKeys {
				playerItem?.removeObserver(self, forKeyPath: key.rawValue);
			}
		}
		didSet {
			for key in AssetKVOKeys.allKeys {
				playerItem?.addObserver(self, forKeyPath: key.rawValue, options: [.new], context: nil);
			}
			player.replaceCurrentItem(with: playerItem);
		}
	}

	private var bufferState: BufferState = .none {
		didSet {
			switch (bufferState, oldValue) {
				case (.none, _):
					bufferProgressChanged?(nil);
				case (.monitoring(let currentId, _), .monitoring(let oldId, _)) where currentId != oldId:
					bufferProgressChanged?(nil);
				case (.monitoring(let trackId, _), _):
					let indexPath = self.indexPath(trackId: trackId);
					bufferProgressChanged?(indexPath);
			}
		}
	}
	
	private var playbackState: PlaybackState = .fine;
	
	private var downloadState: SoundtrackDownloadState = .none {
		didSet {
			downloadStateChanged?(downloadState);
		}
	}
	
	// MARK: - Lifecycle
	init(occasion: OccasionRecord, assets: VisheoRenderingAssets, soundtracksService: SoundtracksService, loggingService: EventLoggingService, editMode: Bool = false) {
		self.occasion = occasion
		self.soundtracksService = soundtracksService
		self.loggingService = loggingService;
		self.assets = assets
		
		switch assets.soundtrackSelection {
			case .none:
				selectedSoundtrackId = nil;
			case .fallback:
				selectedSoundtrackId = -1;
			case .cached(let id, _):
				selectedSoundtrackId = id;
		}
		
		super.init();
		
		for key in PlayerKVOKeys.allKeys {
			player.addObserver(self, forKeyPath: key.rawValue, options: [.new], context: nil);
		}
	}
	
	deinit {
		for observer in observers.values {
			NotificationCenter.default.removeObserver(observer);
		}
	}
	
	// MARK: - Datasource
	var soundtracksCount: Int {
		return occasion.soundtracks.count + 1;
	}
	
	func soundtrackCellModel(at index: Int) -> SoundtrackCellModel {
		if index == 0 {
			return VisheoSoundtrackCellModel.empty(selected: selectedSoundtrackId == nil);
		}
		
		let soundtrack = occasion.soundtracks[index - 1];
		let selected = (soundtrack.id == selectedSoundtrackId);
		
		var progress: Double? = nil;
		if case .monitoring(let trackId, let bufferProgress) = bufferState, soundtrack.id == trackId {
			progress = bufferProgress;
		}
		
		return VisheoSoundtrackCellModel(title: soundtrack.title, selected: selected, progress: progress);
	}
	
	// MARK: - Actions
	func selectSoundtrack(at index: Int) {
		var track: OccasionSoundtrack? = nil;
		
		switch index {
			case 0:
				track = nil;
			default:
				track = occasion.soundtracks[index - 1];
		}
		
		selectedSoundtrackId = track?.id;
		stream(soundtrack: track);
	}
	
	func confirmSelection(){
		player.pause();
		bufferState = .none
		
		let id = selectedSoundtrackId;
		let soundtrack = occasion.soundtracks.filter{ $0.id == id }.first;
		
		downloadSoundtrack(soundtrack: soundtrack) { [weak self] (results) in
			guard let `self` = self, case .success(let url) = results else {
				return;
			}

			self.teardown();
			
			switch id {
				case .some(let value):
					self.assets.setSoundtrack(.cached(id: value, url: url));
				case .none:
					self.assets.setSoundtrack(.none);
			}
			
			self.loggingService.log(event: SoundtrackChangedEvent(), id: self.assets.creationInfo.visheoId);
			self.router?.goBack(with: self.assets);
		}
	}
	
	func cancelSelection() {
		let id = selectedSoundtrackId;
		if let soundtrack = occasion.soundtracks.filter({ $0.id == id }).first {
			soundtracksService.cancelDownloads(except: soundtrack, completion: nil);
		}
		
		teardown();
		router?.goBack(with: assets);
	}
	
	func statusText(for state: SoundtrackDownloadState) -> String? {
		switch state {
			case .downloading:
				return NSLocalizedString("Downloading the Music for Visheo", comment: "");
			case .failed:
				return NSLocalizedString("Download failed", comment: "");
			default:
				return nil;
		}
	}
	
	var canConfirmSelection: Bool {
		switch selectedSoundtrackId {
			case .some(let value) where value >= 0:
				return true;
			case .none:
				return true;
			default:
				return false;
		}
	}
	
	// MARK: - Private
	private func downloadSoundtrack(soundtrack: OccasionSoundtrack?, completion: @escaping ((VisheoVideo.Result<URL?>) -> Void))
	{
		guard let `soundtrack` = soundtrack else {
			completion(.success(value: nil));
			return;
		}
		
		if let url = soundtracksService.cacheURL(for: soundtrack), soundtracksService.soundtrackIsCached(soundtrack: soundtrack) {
			completion(.success(value: url));
			return;
		}
		
		downloadState = .downloading(progress: 0.0);
		
		observe(.soundtrackDownloadFinished, soundtrack: soundtrack, key: .downloadLocation) { [weak self] (url: URL) in
			self?.downloadState = .done;
			completion(.success(value: url));
		}
		
		observe(.soundtrackDownloadFailed, soundtrack: soundtrack, key: .error) { [weak self] (error: Error) in
			self?.downloadState = .failed;
			completion(.failure(error: error));
		}
		
		observe(.soundtrackDownloadProgressed, soundtrack: soundtrack, key: .progress) { [weak self] (progress: Double) in
			self?.downloadState = .downloading(progress: progress);
		}
		
		soundtracksService.cancelDownloads(except: soundtrack) { [weak self] in
			self?.soundtracksService.download(soundtrack);
		}
	}
	
	private func observe<T>(_ notification: Notification.Name,
							soundtrack: OccasionSoundtrack,
						 key: SoundtracksServiceNotificationKeys,
						 handler: @escaping ((T) -> Void))
	{
		if let observer = observers[notification] {
			NotificationCenter.default.removeObserver(observer, name: notification, object: nil);
		}
		
		let observer = NotificationCenter.default.addObserver(forName: notification, object: nil, queue: OperationQueue.main) { notification in
			let userInfo = notification.userInfo;
			guard let id = userInfo?[SoundtracksServiceNotificationKeys.trackId] as? Int, let value = userInfo?[key] as? T, id == soundtrack.id else {
				return;
			}
			handler(value);
		}
		
		observers[notification] = observer;
	}
	
	private func teardown() {
		player.pause();
		
		for key in PlayerKVOKeys.allKeys {
			player.removeObserver(self, forKeyPath: key.rawValue)
		}
		
		for key in AssetKVOKeys.allKeys {
			playerItem?.removeObserver(self, forKeyPath: key.rawValue);
		}
	}
	
	private func indexPath(trackId: Int?) -> IndexPath {
		guard let index = occasion.soundtracks.index(where: { $0.id == trackId }) else {
			return IndexPath(item: 0, section: 0);
		}
		return IndexPath(item: index + 1, section: 0);
	}
	
	private func stream(soundtrack: OccasionSoundtrack?) {
		guard let track = soundtrack, let url = soundtracksService.playbackURL(for: track) else {
			playerItem = nil;
			bufferState = .none;
			return;
		}
		
		if case .monitoring(let trackId, _) = bufferState, trackId == track.id {
			switch player.timeControlStatus {
				case .paused:
					player.play();
				case .playing:
					player.pause();
				default:
					break;
			}
			return;
		}
		
		bufferState = .monitoring(id: track.id, progress: 0.0);
		playerItem = AVPlayerItem(url: url);
		player.play();
	}
	
	private func calculateBufferProgress() {
		guard case .monitoring(let trackId, _) = bufferState else {
			return;
		}
		
		var progress: Double = 0.0;
		
		defer {
			bufferState = .monitoring(id: trackId, progress: progress);
		}
		
		guard let item = playerItem, !item.duration.isIndefinite, CMTimeGetSeconds(item.duration) > 0.0 else {
			return;
		}
		
		guard let loadedRange = item.loadedTimeRanges.first?.timeRangeValue, loadedRange.start == kCMTimeZero else {
			return;
		}
		
		progress = Double(loadedRange.duration.value) / Double(item.duration.value);
	}
	
	private func updatePlayerStatus() {
		var playbackError: Error? = nil;
		
		switch (player.currentItem?.error, player.error) {
			case (.some(let error), _):
				playbackError = error;
			case (_, .some(let error)):
				playbackError = error;
			default:
				break;
		}
		
		if let e = playbackError {
			bufferState = .none;
			playbackState = .failed(error: e);
		} else {
			playbackState = .fine;
		}
	}
	
	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		
		if let item = object as? AVPlayerItem, let path = keyPath, item == playerItem {
			switch path {
				case AssetKVOKeys.duration.rawValue,
					 AssetKVOKeys.timeRanges.rawValue:
					calculateBufferProgress();
				case AssetKVOKeys.status.rawValue:
					updatePlayerStatus();
				default:
					break;
			}
			return;
		}
		
		if let item = object as? AVPlayer, let path = keyPath, item == player {
			switch path {
				case PlayerKVOKeys.status.rawValue:
					updatePlayerStatus();
				default:
					break;
			}
			return;
		}
	
		super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context);
	}
}
