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
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        Database.database().isPersistenceEnabled = true
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
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoRenderingProgress, object: nil, queue: OperationQueue.main) { (notification) in
            let info = notification.userInfo!
            print("Render Visheo - \(info[Notification.Keys.visheoId]), progress \(info[Notification.Keys.progress] as! Double * 100)")
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoUploadingProgress, object: nil, queue: OperationQueue.main) { (notification) in
            let info = notification.userInfo!
            print("upload Visheo - \(info[Notification.Keys.visheoId]), progress \(info[Notification.Keys.progress] as! Double * 100)")
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationFailed, object: nil, queue: .main) { (notification) in
            let info = notification.userInfo!
            print("CREATE FAILED Visheo - \(info[Notification.Keys.visheoId]), error \(info[Notification.Keys.error])")
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.visheoCreationSuccess, object: nil, queue: .main) { (notification) in
            let info = notification.userInfo!
            print("CREATE SUCCESS Visheo - \(info[Notification.Keys.visheoId])")
        }
        
        
        let appState           = VisheoAppStateService()
        let authService        = VisheoAuthorizationService()
        let inputValidator     = VisheoUserInputValidator()
        let occasionsList      = VisheoOccasionsListService()
        let permissionsService = VisheoAppPermissionsService()
        let renderingService   = VisheoRenderingService()
        let creationService    = VisheoCreationService(userInfoProvider: authService,
                                                       rendererService: renderingService)
        
        let purchasesInfo = DummyUserPurchasesInfo(premiumCardsNumber: 2)
        return RouterDependencies(appStateService: appState,
                                                appPermissionsService: permissionsService,
                                                authorizationService: authService,
                                                userInputValidator: inputValidator,
                                                occasionsListService: occasionsList,
                                                purchasesInfo:  purchasesInfo,
                                                renderingService: renderingService,
                                                creationService: creationService)
    }
    
    // MARK: Appearance setup
    
    func setupAppearance() {
        let segmentFont = UIFont(name: "Roboto-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedStringKey.font: segmentFont], for: .normal)
    }

}

