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
	case rendering
	case ready(item: AVPlayerItem)
	case failed(error: Error)
}


protocol PreviewViewModel : class {
    func editCover()
    func editPhotos()
    func editVideo()
    
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
         purchasesInfo: UserPurchasesInfo) {
        self.assets = assets
        self.permissionsService = permissionsService
        self.authService = authService
        self.purchasesInfo = purchasesInfo
    }
	
	func renderPreview()
	{
		guard case .pending = renderStatus else {
			return;
		}
		
		let audio = Bundle.main.path(forResource: "beginning", ofType: "m4a");
		let audioURL = URL(fileURLWithPath: audio!);
		let videoURL = assets.videoUrl//URL(fileURLWithPath: video!);
		
		let quality = RenderQuality.res480;
		
		renderStatus = .rendering;
		
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
			case .rendering:
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
    
    func sendVisheo() {
        if authService.isAnonymous {
            router?.showRegistration(with: assets)
        } else if purchasesInfo.premiumCardsNumber == 0 {
            router?.showCardTypeSelection(with: assets)
        } else {
            router?.sendVisheo(with: assets)
        }
        
    }

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
		let frames = [assets.coverUrl] + assets.photoUrls + [videoSnapshot];
		
		renderContainer = PhotosAnimation(frames: frames, quality: quality);
		
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
}
