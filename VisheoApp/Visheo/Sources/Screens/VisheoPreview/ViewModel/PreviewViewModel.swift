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
	
	func renderPreview()
	var previewRenderCallback: ((PreviewRenderStatus) -> Void)? { get set }
	
	func statusText(for status: PreviewRenderStatus) -> String?;
}

class VisheoPreviewViewModel : PreviewViewModel {
    weak var router: PreviewRouter?
    let assets: VisheoRenderingAssets
    let permissionsService : AppPermissionsService
    let authService: AuthorizationService
    let purchasesInfo: UserPurchasesInfo
	
	let extractor = VideoThumbnailExtractor();
	var renderContainer: Container? = nil;
	var previewRenderCallback: ((PreviewRenderStatus) -> Void)? = nil;
	
	
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
		let audio = Bundle.main.path(forResource: "beginning", ofType: "m4a");
		let audioURL = URL(fileURLWithPath: audio!);
		let videoURL = assets.videoUrl//URL(fileURLWithPath: video!);
		
		let size = CGSize(width: 480.0, height: 480.0);
		
		previewRenderCallback?(.rendering)
		
		firstly {
			fetchVideoScreenshot(url: videoURL)
		}
		.then { url in
			self.renderTimeLine(videoSnapshot: url)
		}
		.then { url -> VisheoVideoComposition in
			let video = VisheoVideo(timeline: url, video: videoURL, audio: audioURL, size: size);
			return try video.prepareComposition()
		}
		.then { composition -> AVPlayerItem in
			let item = AVPlayerItem(asset: composition.mainComposition);
			item.videoComposition = composition.videoComposition;
			item.audioMix = composition.audioMix;
			return item;
		}
		.then { [weak self] item -> Void in
			self?.previewRenderCallback?(.ready(item: item));
		}
		.catch { [weak self] error in
			self?.previewRenderCallback?(.failed(error: error));
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
	
	private func renderTimeLine(videoSnapshot: URL) -> Promise<URL>
	{
		let frames = [assets.coverUrl!] + assets.photoUrls + [videoSnapshot];
		
		renderContainer = Container(frames: frames, size: CGSize(width: 480.0, height: 480.0));
		
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
