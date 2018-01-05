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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    enum ConfigConstants {
        static let freeVisheoLifetime = 15
    }
    
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

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }

    // MARK: Routing dependencies
    
    func dependencies() -> RouterDependencies {
        let appState           = VisheoAppStateService()
		let eventLoggingService = VisheoEventLoggingService();
		let authService        = VisheoAuthorizationService(appState: appState,
															loggingService: eventLoggingService)
        let inputValidator     = VisheoUserInputValidator()
        let occasionsList      = VisheoOccasionsListService()
        let permissionsService = VisheoAppPermissionsService()
		let renderingService   = VisheoRenderingService(appStateService: appState);
        let creationService    = VisheoCreationService(userInfoProvider: authService,
													   rendererService: renderingService,
													   appStateService: appState,
													   loggingService: eventLoggingService,
                                                       freeLifetime: ConfigConstants.freeVisheoLifetime)
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
                                                occasionsListService: occasionsList,
                                                visheosListService: visheosListService,
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

}

