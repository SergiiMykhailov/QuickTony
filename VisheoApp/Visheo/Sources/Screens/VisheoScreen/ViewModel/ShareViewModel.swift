//
//  ShareVisheoViewModel.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/23/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation
import Photos
import UserNotifications

import Firebase

enum VisheoCreationStatus {
    case rendering(progress: Double)
    case uploading(progress: Double)
    case ready
}

protocol ShareViewModel : class, AlertGenerating {
    var coverImageUrl : URL? {get}
    var visheoUrl : URL? {get}
    var visheoLink : String? {get}
    var showBackButton : Bool {get}
	var shouldRetryProcessing: Bool { get }
    
    var isVisheoMissing : Bool {get}
    
    var renderingTitle : String {get}
    var uploadingTitle : String {get}
	
	var notificationsAuthorization: ((String) -> Void)? { get set }
    
    var creationStatusChanged : (()->())? {get set}
    var creationStatus : VisheoCreationStatus {get}
	
	var reminderDate: Date { get }
	var minimumReminderDate: Date { get }
	func setReminderDate(_ date: Date);
    
    func startRendering()
    
    var showRetryLaterError : ((String)->())? {get set}
    func retry()
    func tryLater()
    func showMenu()
    
    func saveVisheo()
    func deleteVisheo()
	
	func openSettings()
	
	func trackLinkCopied()
	func trackLinkShared();
}

extension ShareViewModel {
	var minimumReminderDate: Date {
		return Date();
	}
	
	fileprivate var initialReminderDate: Date {
		let calendar = Calendar(identifier: .gregorian);
		let now = Date();
		let components = calendar.dateComponents([.year, .month, .day], from: now);
		let startOfToday = calendar.date(from: components) ?? now;
		
		var addition = DateComponents();
		addition.day = 1;
		addition.hour = 12;
		
		let final = calendar.date(byAdding: addition, to: startOfToday) ?? now;
		return final;
	}
}

class ExistingVisheoShareViewModel: ShareViewModel {
    var isVisheoMissing: Bool  {
        guard let creationDate = visheoRecord.creationDate, let lifetime = visheoRecord.lifetime else {
            return false
        }
        
        return creationDate.daysFromNow < -lifetime
    }
    
    var showBackButton: Bool {
        return true
    }
	
	var shouldRetryProcessing: Bool {
		return false;
	}
    
    var coverImageUrl: URL? {
        return visheoRecord.coverUrl
    }
    
    var visheoUrl: URL? {
        if isVisheoMissing {
            return nil
        }
        if let localUrl = visheosCache.localUrl(for: visheoRecord.id) {
            return localUrl
        } else if let remoteUrl = visheoRecord.videoUrl {
            //Here we just start download visheo to use it next time. And return remote url to be shown in AVPlayer
            // If this will be not enough we ll be able to replace this with only one downoad to cache and than pass it to player
            visheosCache.downloadVisheo(with: visheoRecord.id, remoteUrl: remoteUrl)
        }
        return visheoRecord.videoUrl
    }
    
    var visheoLink: String? {
        return visheoRecord.visheoLink
    }
    
    var renderingTitle: String = ""
    var uploadingTitle: String = ""
    var creationStatus: VisheoCreationStatus = .ready
    func startRendering() {}
    func retry() {}
    func tryLater() {}
    
    var creationStatusChanged: (() -> ())?
    var successAlertHandler: ((String) -> ())?
    var warningAlertHandler: ((String) -> ())?
    var showRetryLaterError: ((String) -> ())?
	var notificationsAuthorization: ((String) -> Void)?
	
	lazy var reminderDate: Date = initialReminderDate;
    weak var router: ShareRouter?
    private let visheoRecord : VisheoRecord
    private let visheoService : CreationService
    private let visheosCache : VisheosCache
	private let userNotificationsService: UserNotificationsService
	private let loggingService: EventLoggingService;
    
	init(record: VisheoRecord, visheoService: CreationService, cache: VisheosCache, notificationsService: UserNotificationsService, loggingService: EventLoggingService) {
        self.visheoRecord = record
        self.visheoService = visheoService
        self.visheosCache = cache
		self.userNotificationsService = notificationsService;
		self.loggingService = loggingService;
    }
    
    func showMenu() {}
    
    func deleteVisheo() {
        self.visheoService.deleteVisheo(with: visheoRecord.id)
        router?.goToRoot()
    }
    
    func saveVisheo() {
        if let visheoUrl = visheoUrl {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: visheoUrl)
            }) {[weak self] (success, error) in
                if success {
                    self?.successAlertHandler?(NSLocalizedString("Your visheo was saved to the gallery.", comment: "Successfully save visheo to gallery text"))
                } else {
                    self?.warningAlertHandler?(NSLocalizedString("Oops... Something went wrong.", comment: "Failed to save visheo to gallery text"))
                }
            }
        }
    }
	
	func setReminderDate(_ date: Date) {
		reminderDate = date;
		let title = NSString.localizedUserNotificationString(forKey: "Send your visheo!", arguments: nil);
		
		userNotificationsService.schedule(at: date, text: title, visheoId: visheoRecord.id) { [weak self] error in
			guard let e = error else {
				self?.loggingService.log(event: ReminderEvent())
				self?.successAlertHandler?(NSLocalizedString("Reminder was set.", comment: "Successfully set reminder to share visheo"));
				return;
			}
			switch e {
				case UserNotificationsServiceError.authorizationDenied:
					self?.notificationsAuthorization?(NSLocalizedString("Please enable notifications in device settings.", comment: "Failed to set reminder"));
				default:
					self?.warningAlertHandler?(NSLocalizedString("Oops... Something went wrong.", comment: "Failed to set reminder"));
			}
		}
	}
	
	func openSettings() {
		if let url = URL(string: UIApplicationOpenSettingsURLString) {
			UIApplication.shared.open(url, options: [:], completionHandler: nil);
		}
	}
	
	func trackLinkCopied() {
		loggingService.log(event: VisheoURLCopiedEvent())
	}
	
	func trackLinkShared() {
		loggingService.log(event: VisheoSharedEvent());
	}
}

class ShareVisheoViewModel : ShareViewModel {
    var isVisheoMissing: Bool {
        return false
    }
    
    var successAlertHandler: ((String) -> ())?
    
    var warningAlertHandler: ((String) -> ())?
    
    var showRetryLaterError: ((String) -> ())?
	var notificationsAuthorization: ((String) -> Void)?
    
    var visheoUrl: URL?
    var visheoLink: String?
	lazy var reminderDate: Date = initialReminderDate;
    
    var showBackButton: Bool {
		if let _ = record {
			return true;
		}
		return false;
    }    
    
    var coverImageUrl: URL? {
        return assets?.coverUrl ?? record?.coverUrl
    }
    
    var creationStatusChanged: (() -> ())? {
        didSet {
            creationStatusChanged?()
        }
    }
	
	var delayStatusReporting: TimeInterval? = nil;
	var creationStatus: VisheoCreationStatus = .rendering(progress: 0.3) {
		willSet {
			switch (creationStatus, newValue) {
				case (.rendering(let progress), .uploading) where progress >= 1.0:
					delayStatusReporting = Date().timeIntervalSince1970;
				case (_, .ready):
					delayStatusReporting = nil;
				default:
					break;
			}
		}
		
        didSet {
			if let delay = delayStatusReporting, Date().timeIntervalSince1970 - delay < 0.4 {
				return;
			}
			delayStatusReporting = nil;
            creationStatusChanged?()
        }
    }
    
    var renderingTitle: String = NSLocalizedString("We are rendering your Visheo", comment: "rendering visheo progress title")
    
    var uploadingTitle: String = NSLocalizedString("We are uploading your Visheo", comment: "uploading visheo progress title")
    
    weak var router: ShareRouter?
    private let renderingService : RenderingService
    private let creationService : CreationService
	private let userNotificationsService: UserNotificationsService
    private let sharePremium : Bool
	private let loggingService: EventLoggingService;
	private var assets: VisheoRenderingAssets?;
	private var record: VisheoRecord?;
    
	init(assets: VisheoRenderingAssets, renderingService: RenderingService, creationService: CreationService, notificationsService: UserNotificationsService, loggingService: EventLoggingService, sharePremium: Bool) {
        self.renderingService = renderingService
        self.creationService = creationService
		self.userNotificationsService = notificationsService;
		self.loggingService = loggingService;
        self.sharePremium = sharePremium
		self.assets = assets;
    }
	
	init(record: VisheoRecord, renderingService: RenderingService, creationService: CreationService, notificationsService: UserNotificationsService, loggingService: EventLoggingService) {
		self.renderingService = renderingService
		self.creationService = creationService
		self.userNotificationsService = notificationsService;
		self.loggingService = loggingService;
		self.record = record;
		
		guard let info = self.creationService.unfinishedInfo(with: record.id) else {
			sharePremium = false;
			return;
		}
		
		sharePremium = info.premium;
		if info.visheoCreated {
			let progress = creationService.uploadProgress(for: record.id) ?? 0.0;
			creationStatus = .uploading(progress: progress);
		} else {
			creationStatus = .rendering(progress: 0.3);
		}
	}
	
	var currentVisheoId: String {
		return (assets?.creationInfo.visheoId ?? record?.id)!;
	}
	
	var shouldRetryProcessing: Bool {
		if let _ = record {
			return true;
		}
		return false;
	}
	
	func setReminderDate(_ date: Date) {
		reminderDate = date;
		let title = NSString.localizedUserNotificationString(forKey: "Send your visheo!", arguments: nil);
		
		userNotificationsService.schedule(at: date, text: title, visheoId: currentVisheoId) { [weak self] error in
			guard let e = error else {
				self?.loggingService.log(event: ReminderEvent())
				self?.successAlertHandler?(NSLocalizedString("Reminder was set.", comment: "Successfully set reminder to share visheo"));
				return;
			}
			switch e {
				case UserNotificationsServiceError.authorizationDenied:
					self?.notificationsAuthorization?(NSLocalizedString("Please enable notifications in device settings.", comment: "Failed to set reminder"));
				default:
					self?.warningAlertHandler?(NSLocalizedString("Oops... Something went wrong.", comment: "Failed to set reminder"));
			}
		}
	}
    
    func retry() {
        creationService.retryCreation(for: currentVisheoId)
    }
    
    func tryLater() {
        router?.goToRoot()
    }
    
    func deleteVisheo() {
        self.creationService.deleteVisheo(with: currentVisheoId)
        router?.goToRoot()
    }
    
    func saveVisheo() {
        if let visheoUrl = visheoUrl {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: visheoUrl)
            }) {[weak self] (success, error) in
                if success {
                    self?.successAlertHandler?(NSLocalizedString("Your visheo was saved to the gallery.", comment: "Successfully save visheo to gallery text"))
                } else {
                    self?.warningAlertHandler?(NSLocalizedString("Oops... Something went wrong.", comment: "Failed to save visheo to gallery text"))
                }
            }
        }
    }
	
	func trackLinkCopied() {
		loggingService.log(event: VisheoURLCopiedEvent())
	}
	
	func trackLinkShared() {
		loggingService.log(event: VisheoSharedEvent());
	}
    
    func startRendering() {
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoRenderingProgress, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let progress = info[Notification.Keys.progress] as? Double,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.currentVisheoId == visheoId else {return}

            self?.creationStatus = .rendering(progress: progress)
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoUploadingProgress, object: nil, queue: OperationQueue.main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let progress = info[Notification.Keys.progress] as? Double,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.currentVisheoId == visheoId else {return}
            
            self?.creationStatus = .uploading(progress: progress)
		}
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationFailed, object: nil, queue: .main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.currentVisheoId == visheoId,
                let error = info[Notification.Keys.error] as? CreationError else {return}
            
            switch error {
            case .uploadFailed:
                strongSelf.showRetryLaterError?(NSLocalizedString("Upload error. Retry?", comment: "Upload visheo error"))
            case .renderFailed:
                strongSelf.showRetryLaterError?(NSLocalizedString("Render error. Retry?", comment: "Render visheo error"))
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationSuccess, object: nil, queue: .main) {[weak self] (notification) in
            guard let strongSelf = self,
                let info = notification.userInfo,
                let visheoId = info[Notification.Keys.visheoId] as? String,
                strongSelf.currentVisheoId == visheoId else {return}
            
            strongSelf.visheoUrl = info[Notification.Keys.visheoUrl] as? URL
            strongSelf.visheoLink = info[Notification.Keys.visheoShortLink] as? String
            strongSelf.creationStatus = .ready
        }
		
		if let `assets` = assets {
			self.creationService.createVisheo(from: assets, premium: sharePremium)
		} else if let id = record?.id {
			self.creationService.retryCreation(for: id);
		}
    }
    
    func showMenu() {
        router?.showMenu()
    }
	
	func openSettings() {
		if let url = URL(string: UIApplicationOpenSettingsURLString) {
			UIApplication.shared.open(url, options: [:], completionHandler: nil);
		}
	}
}
