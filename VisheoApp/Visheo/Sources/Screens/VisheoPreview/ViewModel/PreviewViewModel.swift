//
//  PreviewViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/20/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import VisheoVideo
import PromiseKit


enum PreviewRenderStatus
{
	case pending
	case waitingForResources(start: TimeInterval)
	case rendering
	case ready(item: AVPlayerItem)
	case failed(error: Error, shouldFallback: Bool)
}


protocol PreviewViewModel : class {
    func editCover()
    func editPhotos()
    func editVideo()
	func editSoundtrack()
    
	func buttonSaveWasClicked()
    func sendVisheo()
    
    var assets : VisheoRenderingAssets {get}
	var renderStatus: PreviewRenderStatus { get }
	
	func renderPreview()
	var previewRenderCallback: ((PreviewRenderStatus) -> Void)? { get set }
	
	func statusText(for status: PreviewRenderStatus) -> String?;
	func isActivityRunning(for status: PreviewRenderStatus) -> Bool;
	func shouldRetryRender(for status: PreviewRenderStatus) -> Bool;
	
	func handleAssetsUpdate(_ assets: VisheoRenderingAssets);
    
    var premiumUsageFailedHandler : (()->())? {get set}
}

class VisheoPreviewViewModel : PreviewViewModel
{
	private enum PreviewGenerationError: Error {
		case resourceTimeout
	}
	
    weak var router: PreviewRouter?
    private (set) var assets: VisheoRenderingAssets
    private let permissionsService: AppPermissionsService
    private let authService: AuthorizationService
    private let purchasesInfo: UserPurchasesInfo
	private let appStateService: AppStateService;
	private let soundtracksService: SoundtracksService
    private let premCardsService: PremiumCardsService
    private let loggingService: EventLoggingService
	
	let extractor = VideoThumbnailExtractor();
	var renderContainer: PhotosAnimation? = nil;
	var previewRenderCallback: ((PreviewRenderStatus) -> Void)? = nil;
    var premiumUsageFailedHandler: (() -> ())?
	
	private let soundtrackFetchTimeout: TimeInterval = 5;
	private var displayLink: CADisplayLink? = nil;
	
	private (set) var renderStatus: PreviewRenderStatus = .pending {
		didSet {
			previewRenderCallback?(renderStatus);
		}
	}
	
	
    init(assets: VisheoRenderingAssets,
         permissionsService: AppPermissionsService,
         authService: AuthorizationService,
         purchasesInfo: UserPurchasesInfo,
		 appStateService: AppStateService,
		 soundtracksService: SoundtracksService,
         premCardsService: PremiumCardsService,
         eventLoggingService: EventLoggingService) {
        self.assets = assets
        self.permissionsService = permissionsService
        self.authService = authService
        self.purchasesInfo = purchasesInfo
		self.appStateService = appStateService
		self.soundtracksService = soundtracksService
        self.premCardsService = premCardsService
        self.loggingService = eventLoggingService
		
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoPreviewViewModel.soundtrackDownloaded(_:)), name: .soundtrackDownloadFinished, object: nil);
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoPreviewViewModel.soundtrackDownloadFailed(_:)), name: .soundtrackDownloadFailed, object: nil);
    }
	
	deinit {
		stopResourceTimeoutMonitor();
		NotificationCenter.default.removeObserver(self);
	}
	
	
	func renderPreview() {
		switch renderStatus {
			case .pending, .waitingForResources:
				break;
			case .failed(_, let shouldFallback) where shouldFallback:
				break;
			default:
				return;
		}
		
		var audioURL: URL?;
		var outroURL: URL?;
		var fallbackAudioURL: URL?;
		
		if let path = Bundle.main.path(forResource: "default_outro", ofType: "mov") {
			outroURL = URL(fileURLWithPath: path);
		}
		
		if let path = Bundle.main.path(forResource: "beginning", ofType: "m4a") {
			fallbackAudioURL = URL(fileURLWithPath: path);
		}
		
		let currentTime = Date().timeIntervalSince1970;
		
		if case .cached(_, let soundtrackURL) = assets.soundtrackSelection, let soundtrack = assets.selectedSoundtrack {
			if case .failed(_, let shouldFallback) = renderStatus, shouldFallback {
				audioURL = fallbackAudioURL;
				assets.setSoundtrack(.fallback(url: fallbackAudioURL));
			} else if let url = soundtrackURL {
				audioURL = url;
			} else if soundtracksService.soundtrackIsCached(soundtrack: soundtrack) {
				let url = soundtracksService.cacheURL(for: soundtrack);
				assets.setSoundtrack(.cached(id: soundtrack.id, url: url));
				audioURL = assets.soundtrackURL;
			} else {
				renderStatus = .waitingForResources(start: currentTime);
				soundtracksService.download(soundtrack);
				launchResourceTimeoutMonitor();
				return;
			}
		} else if case .fallback(let url) = assets.soundtrackSelection {
			audioURL = url;
		}
		
		renderStatus = .rendering;
			
		let videoURL = assets.videoUrl
		let quality = RenderQuality.res720;
		
		firstly {
			fetchVideoScreenshot(url: videoURL)
		}
		.then { url in
			self.renderTimeLine(videoSnapshot: url, quality: quality);
		}
		.then { url -> VisheoVideoComposition in
			let video = VisheoRender(timeline: url, video: videoURL, audio: audioURL, outro: outroURL, quality: quality);
			return try video.prepareComposition()
		}
		.then { composition -> AVPlayerItem in
			let item = AVPlayerItem(asset: composition.mainComposition);
			item.videoComposition = composition.videoComposition;
			item.audioMix = composition.audioMix;
			return item;
		}
		.then { [weak self] item -> Void in
			self?.renderStatus = .ready(item: item);
		}
		.catch { [weak self] error in
			switch error {
				case RenderError.missingAudioTrack:
					self?.renderStatus = .failed(error: error, shouldFallback: true);
				default:
					self?.renderStatus = .failed(error: error, shouldFallback: false);
			}
			print("Failed to generate preview \(error)");
		}
	}
	
	func statusText(for status: PreviewRenderStatus) -> String?
	{
		switch status {
			case .rendering,
				 .waitingForResources:
				return "Generating preview...";
			case .failed(_, let shouldFallback) where shouldFallback:
				return "Generating preview...";
			case .failed:
				return "Failed to generate preview";
			default:
				return nil;
		}
	}
	
	func shouldRetryRender(for status: PreviewRenderStatus) -> Bool {
		if case .failed(_, let shouldFallback) = status, shouldFallback {
			return true;
		}
		return false;
	}
	
	func isActivityRunning(for status: PreviewRenderStatus) -> Bool {
		switch status {
			case .rendering,
				 .waitingForResources:
				return true;
			case .failed(_, let shouldFallback) where shouldFallback:
				return true;
			default:
				return false;
		}
	}
	
	func handleAssetsUpdate(_ assets: VisheoRenderingAssets) {
		self.assets = assets;
		renderStatus = .pending;
	}
    
    func editCover() {
        router?.showCoverEdit(with: assets)
    }
    
    func editPhotos() {
        if permissionsService.galleryAccessAllowed {
            router?.showPhotosEdit(with: assets)
        } else {
            router?.showPhotoPermissions(with: assets)
        }
    }
    
    func editVideo() {
        router?.showVideoEdit(with: assets)
    }
	
	func editSoundtrack() {
		router?.showSoundtrackEdit(with: assets);
	}
    
    func buttonSaveWasClicked() {
        self.loggingService.log(event: VisheoSaved())
        sendVisheo()
    }
    
    func sendVisheo() {
        if authService.isAnonymous {
            router?.showRegistration { [weak self] registered in
				if (registered) {
                    //            showProgressCallback?(true)
                    self?.premCardsService.checkUserCardsRemotely {
                        //                self.showProgressCallback?(false)
                        self?.sendVisheo()
                    }
				}
            }
        } else if self.assets.originalOccasion.isFree {
            showSendVisheoScreen()
        } else if purchasesInfo.currentUserSubscriptionState() == .active {
            showSendVisheoScreen()
        } else if purchasesInfo.currentUserSubscriptionState() == .expired {
//            showProgressCallback?(true)
            premCardsService.checkSubscriptionStateRemotely() { [weak self] purchaseResult, error in
//                self.showProgressCallback?(false)
                let assets = self?.assets
                if let purchaseResult = purchaseResult {
                    switch purchaseResult {
                        case .purchased(_,_):
                            self?.showSendVisheoScreen()
                        case .expired(_,_):
                            self?.router?.showCardTypeSelection(with: assets!)
                        case .notPurchased:
                            self?.router?.showCardTypeSelection(with: assets!)
                    }
                } else if let error = error {
                    //TODO: handle error
                    print(error)
                }
            }
        } else if purchasesInfo.currentUserPremiumCards == 0 {
            router?.showCardTypeSelection(with: assets)
        } else {
            premCardsService.usePremiumCard(completion: { (success) in
                if success {
                    self.showSendVisheoScreen()
                } else {
                    self.premiumUsageFailedHandler?()
                }
            })
        }
    }
	
    private func showSendVisheoScreen(withPremium premium: Bool = true) {
        router?.sendVisheo(with: self.assets, premium: premium)
    }
    
	private func launchResourceTimeoutMonitor() {
		displayLink = CADisplayLink(target: self, selector: #selector(VisheoPreviewViewModel.timeoutTick));
		displayLink?.add(to: RunLoop.main, forMode: .commonModes);
	}
	
	private func stopResourceTimeoutMonitor() {
		displayLink?.invalidate();
		displayLink = nil;
	}
	
	@objc private func timeoutTick() {
		guard case .waitingForResources(let start) = renderStatus else {
			return;
		}
		
		let currentTime = Date().timeIntervalSince1970;
		guard currentTime - start >= soundtrackFetchTimeout else {
			return;
		}
		
		stopResourceTimeoutMonitor();
		soundtracksService.cancelAllDownloads();
		renderStatus = .failed(error: PreviewGenerationError.resourceTimeout, shouldFallback: true);
	}

	// MARK: - Rendering
	private func fetchVideoScreenshot(url: URL) -> Promise<URL> {
		let asset = AVURLAsset(url: url);

		return Promise { fl, rj in
			extractor.generateThumbnails(asset: asset, frames: [.first], completion: { (result) in
				switch result {
				case .failure(let error):
					rj(error);
				case .success(let result):
					fl(result.first!.image);
				}
			})
		}
		.then { (image: UIImage) -> Promise<URL> in
			var url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true);
			url = url.appendingPathComponent("\(UUID().uuidString).jpg");
			try UIImageJPEGRepresentation(image, 1.0)?.write(to: url);
			return Promise(value: url);
		}
	}
	
	private func renderTimeLine(videoSnapshot: URL, quality: RenderQuality) -> Promise<URL> {
		let settings = appStateService.appSettings.animationSettings;
		let animationSettings = settings.withAssetsCount(assets.photoUrls.count) ?? AnimationSettings();
		
		let cover = AssetRepresentation(assets.coverUrl, .cover);
		let photos = assets.photoUrls.map{ AssetRepresentation($0, .photo) }
		let video = AssetRepresentation(videoSnapshot, .video);
		
		let frames = [cover] + photos + [video];
		
		renderContainer = PhotosAnimation(frames: frames, quality: quality, settings: animationSettings);
		
		return Promise { fl, rj in
			do {
				var url = try FileManager.default.url(for: .cachesDirectory, in: .userDomainMask, appropriateFor: nil, create: true);
				url = url.appendingPathComponent("\(UUID().uuidString).mp4");
				renderContainer?.render(to: url, completion: { (result) in
					switch result {
						case .success:
							fl(url);
						case .failure(let error):
							rj(error);
					}
				});
			}
			catch (let e) {
				rj(e)
			}
		}
	}
	
	// MARK: - Notifications
	@objc private func soundtrackDownloaded(_ notification: Notification) {
		let userInfo = notification.userInfo;
		guard 	let id = userInfo?[SoundtracksServiceNotificationKeys.trackId] as? Int,
				let url = userInfo?[SoundtracksServiceNotificationKeys.downloadLocation] as? URL, id == assets.soundtrackId else {
			return;
		}
		
		assets.setSoundtrack(.cached(id: id, url: url));
		
		if case .waitingForResources = renderStatus {
			stopResourceTimeoutMonitor()
			renderPreview();
		}
	}
	
	@objc private func soundtrackDownloadFailed(_ notification: Notification)
	{
		let userInfo = notification.userInfo;
		guard 	let id = userInfo?[SoundtracksServiceNotificationKeys.trackId] as? Int,
				let error = userInfo?[SoundtracksServiceNotificationKeys.error] as? Error, id == assets.soundtrackId else {
			return;
		}
		
		if case .waitingForResources = renderStatus {
			stopResourceTimeoutMonitor();
			renderStatus = .failed(error: error, shouldFallback: true);
		}
	}
}

