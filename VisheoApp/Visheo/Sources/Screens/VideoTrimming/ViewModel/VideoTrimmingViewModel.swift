//
//  VideoTrimmingViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation
import PryntTrimmerView

enum PlaybackStatus {
    case playing
    case paused
}

protocol VideoTrimmingViewModel : class, ProgressGenerating, WarningAlertGenerating {
    func togglePlayback()
	var player: AVPlayer? { get }
    func setup(trimmerView: TrimmerView)
    
    var assetsChanged : (()->())? {get set}
    var playbackTimeChanged: ((CMTime)->())? {get set}
    var playbackStatusChanged: ((PlaybackStatus)->())? {get set}
    
    var hideBackButton : Bool {get}
    
    func didChange(startTime: CMTime?, endTime: CMTime?, at time: CMTime?, stopMoving: Bool)
    
    func retakeVideo()
    func goBack()
    func confirmTrimming()
}

class VisheoVideoTrimmingViewModel : VideoTrimmingViewModel {
    var assetsChanged: (() -> ())?
    
    var hideBackButton: Bool {
        return editMode
    }
    
    var showProgressCallback: ((Bool) -> ())?
    var warningAlertHandler: ((String) -> ())?
    var playbackStatusChanged: ((PlaybackStatus) -> ())?
    var playbackTimeChanged: ((CMTime) -> ())?
    
    weak var router: VideoTrimmingRouter?
    private (set) var player : AVPlayer?
    private var assets : VisheoRenderingAssets!
    private var playerAsset : AVAsset!
    private var playbackTimeCheckerTimer: Timer?
    
    private var startTime : CMTime?
    private var endTime : CMTime?
    
    private let editMode: Bool
    
    init(assets: VisheoRenderingAssets, editMode: Bool) {
        self.editMode = editMode
        
        update(with: assets)
    }
    
    func update(with assets: VisheoRenderingAssets) {
        self.assets = assets
        playerAsset = AVAsset(url: assets.videoUrl)
        let playerItem = AVPlayerItem(asset: playerAsset)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.removeObserver(self)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoVideoTrimmingViewModel.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
        
        assetsChanged?()
    }
    
    deinit {
		stopPlaybackTimeChecker();
        NotificationCenter.default.removeObserver(self)
    }
    
    func goBack() {
		player?.pause()
		stopPlaybackTimeChecker()
		
        router?.goBackToPhotos()
    }
    
    func retakeVideo() {
		player?.pause()
        stopPlaybackTimeChecker()
        
        if editMode {
            router?.showRetake(with: assets)
        } else {
            assets.removeVideo()
            router?.goBackToCapture()
        }
    }
    
    func setup(trimmerView: TrimmerView) {
		trimmerView.maxDuration = CMTimeGetSeconds(playerAsset.duration);
        trimmerView.asset = playerAsset
    }
    
    func togglePlayback() {
		guard let `player` = self.player else { return }
        if !player.isPlaying {
            player.play()
            playbackStatusChanged?(.playing)
            startPlaybackTimeChecker()
        } else {
            player.pause()
            playbackStatusChanged?(.paused)
            stopPlaybackTimeChecker()
        }
    }
    
    func createPlayerLayer() -> CALayer {
        let layer = AVPlayerLayer(player: player)
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        return layer
    }
    
    func confirmTrimming() {
        showProgressCallback?(true)
        let trimPoints = (startTime ?? CMTime(value: 0, timescale: playerAsset.duration.timescale), endTime ?? playerAsset.duration)
        assets.trimPoints = trimPoints
        trimVideo(sourceURL: assets.videoUrl, destinationURL: assets.trimmedVideoUrl, trimPoints: trimPoints) { (success) in
            DispatchQueue.main.async {
                self.showProgressCallback?(false)
                if success {
                    self.assets.replaceVideoWithTrimmed()
					self.player?.pause()
					self.stopPlaybackTimeChecker();
					
                    if self.editMode {
                        self.router?.goBackFromEdit(with: self.assets)
                    } else {
                        self.router?.showPreview(with: self.assets)
                    }
                } else {
                    self.warningAlertHandler?(NSLocalizedString("An error occured while processing video", comment: "Processing video error text"))
                }
            }
        }
    }
    
    private func startPlaybackTimeChecker() {
        stopPlaybackTimeChecker()
        playbackTimeCheckerTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self,
                                                        selector:
            #selector(VisheoVideoTrimmingViewModel.onPlaybackTimeChecker), userInfo: nil, repeats: true)
    }
    
    private func stopPlaybackTimeChecker() {
        playbackTimeCheckerTimer?.invalidate()
        playbackTimeCheckerTimer = nil
    }
    
    @objc func itemDidFinishPlaying(_ notification: Notification) {
        playbackStatusChanged?(.paused)
        if let startTime = self.startTime {
			player?.seek(to: startTime)
        }
    }
    
    @objc func onPlaybackTimeChecker() {
		guard let `player` = self.player else { return }
        let playBackTime = player.currentTime()
        playbackTimeChanged?(playBackTime)

        guard let startTime = self.startTime, let endTime = self.endTime else {
            return
        }
        
        if playBackTime >= endTime {
			player.seek(to: startTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
            playbackTimeChanged?(startTime)
        }
    }
    
    func didChange(startTime: CMTime?, endTime: CMTime?, at time: CMTime? = nil, stopMoving: Bool) {
        self.startTime = startTime
        self.endTime = endTime
        
        if !stopMoving {
			player?.pause()
            playbackStatusChanged?(.paused)
            stopPlaybackTimeChecker()
        }
        if let currentTime = time {
			player?.seek(to: currentTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
        if stopMoving {
			player?.play()
            playbackStatusChanged?(.playing)
            startPlaybackTimeChecker()
        }
    }
}

extension AVPlayer {
    var isPlaying: Bool {
        return self.rate != 0 && self.error == nil
    }
}

func trimVideo(sourceURL: URL, destinationURL: URL, trimPoints: (CMTime, CMTime), completion: ((Bool)->())?) {
    let options = [
        AVURLAssetPreferPreciseDurationAndTimingKey: true
    ]
    
    let asset = AVURLAsset(url: sourceURL as URL, options: options)
    
    let composition = AVMutableComposition()
    let videoCompTrack = composition.addMutableTrack(withMediaType: .video, preferredTrackID: CMPersistentTrackID())
    let audioCompTrack = composition.addMutableTrack(withMediaType: .audio, preferredTrackID: CMPersistentTrackID())
    
    let assetVideoTrack = asset.tracks(withMediaType: .video).first
    let assetAudioTrack = asset.tracks(withMediaType: .audio).first
    
    var accumulatedTime = kCMTimeZero

    let startTimeForCurrentSlice = trimPoints.0
    let endTimeForCurrentSlice = trimPoints.1
    
    let durationOfCurrentSlice = CMTimeSubtract(endTimeForCurrentSlice, startTimeForCurrentSlice)
    let timeRangeForCurrentSlice = CMTimeRangeMake(startTimeForCurrentSlice, durationOfCurrentSlice)
    
    do {
        if let videoTrack = assetVideoTrack {
            try videoCompTrack?.insertTimeRange(timeRangeForCurrentSlice, of: videoTrack, at: accumulatedTime)
        }
        if let audioTrack = assetAudioTrack {
            try audioCompTrack?.insertTimeRange(timeRangeForCurrentSlice, of: audioTrack, at: accumulatedTime)
        }
        accumulatedTime = CMTimeAdd(accumulatedTime, durationOfCurrentSlice)
    }
    catch _ {
        completion?(false)
    }
    
    guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetHighestQuality) else {
        completion?(false)
        return
    }
	
	try? FileManager.default.removeItem(at: destinationURL);
    
    exportSession.outputURL = destinationURL as URL
    exportSession.outputFileType = AVFileType.mov
    
    exportSession.exportAsynchronously {
        completion?(exportSession.error == nil)
    }
}
