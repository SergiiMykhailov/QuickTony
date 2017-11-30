//
//  SelectSoundtrackViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 11/29/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import AVFoundation

protocol SelectSoundtrackViewModel: class {
	var soundtracksCount: Int { get }
	func soundtrackCellModel(at index: Int) -> SoundtrackCellModel
	func selectSoundtrack(at index: Int);
	
	func cancelSelection()
	func confirmSelection()
	
	var bufferProgressChanged: ((_ indexPath: IndexPath?) -> Void)? { get set }
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
	let assets: VisheoRenderingAssets
	
	private lazy var player = AVPlayer();
	private var selectedSoundtrackId: Int? = nil
	var bufferProgressChanged: ((_ indexPath: IndexPath?) -> Void)? = nil;
	
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
	
	// MARK: - Lifecycle
	init(occasion: OccasionRecord, assets: VisheoRenderingAssets, soundtracksService: SoundtracksService, editMode: Bool = false) {
		self.occasion = occasion
		self.soundtracksService = soundtracksService
		self.assets = assets
		selectedSoundtrackId = assets.soundtrackId;
		
		super.init();
		
		for key in PlayerKVOKeys.allKeys {
			player.addObserver(self, forKeyPath: key.rawValue, options: [.new], context: nil);
		}
	}
	
	deinit {
		for key in PlayerKVOKeys.allKeys {
			player.removeObserver(self, forKeyPath: key.rawValue);
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
	
	func confirmSelection() {
		router?.goBack(with: assets);
	}
	
	func cancelSelection() {
		router?.goBack(with: assets);
	}
	
	
	// MARK: - Private
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
