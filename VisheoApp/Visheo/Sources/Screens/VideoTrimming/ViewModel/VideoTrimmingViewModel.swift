//
//  VideoTrimmingViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import AVFoundation
import PryntTrimmerView
import VisheoVideo

enum PlaybackStatus {
    case playing
    case paused
}

protocol VideoTrimmingViewModel : LongFailableActionViewModel {
    func togglePlayback()
    func createPlayerLayer() -> CALayer
    func setup(trimmerView: TrimmerView)
    
    var playbackTimeChanged: ((CMTime)->())? {get set}
    var playbackStatusChanged: ((PlaybackStatus)->())? {get set}
    
    func didChange(startTime: CMTime?, endTime: CMTime?, at time: CMTime?, stopMoving: Bool)
    
    func cancelTrimming()
    func confirmTrimming()
}

class VisheoVideoTrimmingViewModel : VideoTrimmingViewModel {
    var showProgressCallback: ((Bool) -> ())?
    var warningAlertHandler: ((String) -> ())?
    var playbackStatusChanged: ((PlaybackStatus) -> ())?
    var playbackTimeChanged: ((CMTime) -> ())?
    
    weak var router: VideoTrimmingRouter?
    private var player : AVPlayer!
    private let assets : VisheoRenderingAssets
    private let playerAsset : AVAsset
    private var playbackTimeCheckerTimer: Timer?
    
    private var startTime : CMTime?
    private var endTime : CMTime?
    
    init(assets: VisheoRenderingAssets) {
        self.assets = assets
        playerAsset = AVAsset(url: assets.videoUrl)
        let playerItem = AVPlayerItem(asset: playerAsset)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(self, selector: #selector(VisheoVideoTrimmingViewModel.itemDidFinishPlaying(_:)),
                                               name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: playerItem)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func cancelTrimming() {
        stopPlaybackTimeChecker()
        assets.removeVideo()
        router?.goBack()
    }
    
    func setup(trimmerView: TrimmerView) {
        trimmerView.asset = playerAsset
    }
    
    func togglePlayback() {
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
        trimVideo(sourceURL: assets.videoUrl, destinationURL: assets.trimmedVideoUrl, trimPoints: trimPoints) { (success) in
            DispatchQueue.main.async {
                self.showProgressCallback?(false)
                if success {
//self.export(assets: self.assets);
                    self.router?.showPreview(with: self.assets)
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
            player.seek(to: startTime)
        }
    }
    
    @objc func onPlaybackTimeChecker() {
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
            player.pause()
            playbackStatusChanged?(.paused)
            stopPlaybackTimeChecker()
        }
        if let currentTime = time {
            player.seek(to: currentTime, toleranceBefore: kCMTimeZero, toleranceAfter: kCMTimeZero)
        }
        if stopMoving {
            player.play()
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
    catch let _ {
        completion?(false)
    }
    
    guard let exportSession = AVAssetExportSession(asset: composition, presetName: AVAssetExportPresetPassthrough) else {
        completion?(false)
        return
    }
	
	try? FileManager.default.removeItem(at: destinationURL);
    
    exportSession.outputURL = destinationURL as URL
    exportSession.outputFileType = AVFileType.mov
    exportSession.shouldOptimizeForNetworkUse = true
    
    exportSession.exportAsynchronously {
        completion?(exportSession.error == nil)
    }
}


extension VideoTrimmingViewModel
{
	func export(assets: VisheoRenderingAssets)
	{
		let audio = Bundle.main.path(forResource: "beginning", ofType: "m4a")!;
		
		var task = RenderTask(quality: .res720);
		
		task.addMedia(assets.coverUrl!, type: .cover);
		task.addMedia(assets.photoUrls, type: .photo);
		task.addMedia(assets.videoUrl, type: .video);
		task.addMedia(URL(fileURLWithPath: audio), type: .audio);
		
		RenderQueue.shared.enqueue(task);
	}
}
