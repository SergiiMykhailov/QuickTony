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
	case waitingForResources
	case rendering
	case ready(item: AVPlayerItem)
	case failed(error: Error)
}


protocol PreviewViewModel : class {
    func editCover()
    func editPhotos()
    func editVideo()
	func editSoundtrack();
	
    func sendVisheo()
    
    var assets : VisheoRenderingAssets {get}
	var renderStatus: PreviewRenderStatus { get }
	
	func renderPreview()
	var previewRenderCallback: ((PreviewRenderStatus) -> Void)? { get set }
	
	func statusText(for status: PreviewRenderStatus) -> String?;
	
	func handleAssetsUpdate(_ assets: VisheoRenderingAssets);
}

class VisheoPreviewViewModel : PreviewViewModel {
    weak var router: PreviewRouter?
    private (set) var assets: VisheoRenderingAssets
    let permissionsService : AppPermissionsService
    let authService: AuthorizationService
    let purchasesInfo: UserPurchasesInfo
	let appStateService: AppStateService;
	let soundtracksService: SoundtracksService
	
	let extractor = VideoThumbnailExtractor();
	var renderContainer: PhotosAnimation? = nil;
	var previewRenderCallback: ((PreviewRenderStatus) -> Void)? = nil;
	
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
		 soundtracksService: SoundtracksService) {
        self.assets = assets
        self.permissionsService = permissionsService
        self.authService = authService
        self.purchasesInfo = purchasesInfo
		self.appStateService = appStateService;
		self.soundtracksService = soundtracksService;
		
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoPreviewViewModel.soundtrackDownloaded(_:)), name: .soundtrackDownloadFinished, object: nil);
		NotificationCenter.default.addObserver(self, selector: #selector(VisheoPreviewViewModel.soundtrackDownloadFailed(_:)), name: .soundtrackDownloadFailed, object: nil);
    }
	
	deinit {
		NotificationCenter.default.removeObserver(self);
	}
	
	
	func renderPreview()
	{
		switch renderStatus {
			case .pending, .waitingForResources:
				break;
			default:
				return;
		}

		renderStatus = .rendering;
		
		var audioURL: URL?;
		
		if let soundtrack = assets.selectedSoundtrack {
			if soundtracksService.soundtrackIsCached(soundtrack: soundtrack) {
				audioURL = soundtracksService.cacheURL(for: soundtrack)
			} else {
				renderStatus = .waitingForResources;
				soundtracksService.download(soundtrack);
				return;
			}
		}
			
		let videoURL = assets.videoUrl
		let quality = RenderQuality.res480;
		
		firstly {
			fetchVideoScreenshot(url: videoURL)
		}
		.then { url in
			self.renderTimeLine(videoSnapshot: url, quality: quality);
		}
		.then { url -> VisheoVideoComposition in
			let video = VisheoVideo(timeline: url, video: videoURL, audio: audioURL, quality: quality);
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
			self?.renderStatus = .failed(error: error);
		}
	}
	
	func statusText(for status: PreviewRenderStatus) -> String?
	{
		switch status {
			case .failed:
				return "Failed to generate preview";
			case .rendering,
				 .waitingForResources:
				return "Generating preview...";
			default:
				return nil;
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
    
    func sendVisheo() {
        if authService.isAnonymous {
            router?.showRegistration {
                self.sendVisheo()
            }
        } else if purchasesInfo.premiumCardsNumber == 0 {
            router?.showCardTypeSelection(with: assets)
        } else {
            router?.sendVisheo(with: assets)
        }
        
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
	
	private func renderTimeLine(videoSnapshot: URL, quality: RenderQuality) -> Promise<URL>
	{
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
		
		assets.setSoundtrack(id: assets.soundtrackId, url: url);
		
		if case .waitingForResources = renderStatus {
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
			renderStatus = .failed(error: error);
		}
	}
}
