//
//  AppDelegate.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 10/31/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import Fabric
import Crashlytics
import Firebase
import GoogleSignIn
import FBSDKLoginKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        
        Database.database().isPersistenceEnabled = true
        Storage.storage().maxUploadRetryTime = 60
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        setupAppearance()
        
        if let launchProxyController = self.window?.rootViewController as? LaunchProxyViewController {            
            let launchProxyRouter = DefaultLaunchProxyRouter(dependencies: dependencies())
            launchProxyRouter.start(with: launchProxyController)
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let facebookHandled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, options: options)
        let googleHandled   = GIDSignIn.sharedInstance().handle(url,
                                                              sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String,
                                                              annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        return facebookHandled || googleHandled
    }

    // MARK: Routing dependencies
    
    func dependencies() -> RouterDependencies {
        let appState           = VisheoAppStateService()
		let eventLoggingService = VisheoEventLoggingService();
		let authService        = VisheoAuthorizationService(appState: appState,
															loggingService: eventLoggingService)
        let inputValidator     = VisheoUserInputValidator()
        let occasionsList      = VisheoOccasionsListService()
        let occasionGroups     = VisheoOccasionGroupsListService(occasionList: occasionsList)
        let permissionsService = VisheoAppPermissionsService()
		let renderingService   = VisheoRenderingService(appStateService: appState);
        let creationService    = VisheoCreationService(userInfoProvider: authService,
													   rendererService: renderingService,
													   appStateService: appState,
													   loggingService: eventLoggingService)
		let soundtracksService = VisheoSoundtracksService();
		let userNotificationsService = VisheoUserNotificationsService();
        let assembly = VisheoRouterAssembly()
		let tipsProviderService = VisheoTipsProviderService()

        let visheosListService = VisheoBoxService(userInfoProvider: authService)
        let visheosCache = VisheosLocalCache()
		let feedbackService = VisheoFeedbackService(userInfoProvider: authService);
        
		let premiumService = VisheoPremiumCardsService(userInfoProvider: authService, loggingService: eventLoggingService)
        return RouterDependencies(appStateService: appState,
                                                appPermissionsService: permissionsService,
                                                authorizationService: authService,
                                                userInfoProvider : authService,
                                                userInputValidator: inputValidator,
                                                visheosListService: visheosListService,
                                                occasionsListService: occasionsList,
                                                occasionGroupsListService: occasionGroups,
                                                purchasesInfo:  premiumService,
                                                renderingService: renderingService,
                                                creationService: creationService,
												soundtracksService: soundtracksService,
												userNotificationsService: userNotificationsService,
												loggingService: eventLoggingService,
												feedbackService: feedbackService,
												tipsProviderService: tipsProviderService,
												routerAssembly: assembly,
												visheosCache: visheosCache,
												premiumCardsService: premiumService)
    }
    
    // MARK: Appearance setup
    
    func setupAppearance() {
        let segmentFont = UIFont(name: "Roboto-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedStringKey.font: segmentFont], for: .normal)
    }

    // MARK: Notifications
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any]) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        print(userInfo)
        
        completionHandler(UIBackgroundFetchResult.newData)
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Unable to register for remote notifications: \(error.localizedDescription)")
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("APNs token retrieved: \(token)")
    }
}
