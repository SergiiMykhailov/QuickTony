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
import FirebaseDynamicLinks
import GoogleSignIn
import FBSDKLoginKit
import UserNotifications
import TwitterKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    var launchProxyRouter: DefaultLaunchProxyRouter?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        FirebaseApp.configure()
        
        Database.database().isPersistenceEnabled = true
        Storage.storage().maxUploadRetryTime = 60
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        TWTRTwitter.sharedInstance().start(withConsumerKey: "rmwotRCcivfCd6LqtBGG7k3sr", consumerSecret: "u2qfzgYROzQo5dvLC7S2VD0zkFLfez4Kag58w4fEvU6AfJW0iU")
        
        
        setupAppearance()
        
        if let launchProxyController = self.window?.rootViewController as? LaunchProxyViewController {            
            launchProxyRouter = DefaultLaunchProxyRouter(dependencies: dependencies())
            launchProxyRouter?.start(with: launchProxyController)
        }
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        if let isDynamicLink = DynamicLinks.dynamicLinks()?.shouldHandleDynamicLink(fromCustomSchemeURL: url),
            isDynamicLink {
            let dynamicLink = DynamicLinks.dynamicLinks()?.dynamicLink(fromCustomSchemeURL: url)
            return launchProxyRouter?.dependencies.invitationService.handleDynamicLink(from: dynamicLink) ?? false
        }
    
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
        let invitationService = VisheoInvitesService(withAuthorizationService: authService, eventLoggingService: eventLoggingService, userInfo: authService)
        let userNotificationsService = VisheoUserNotificationsService(withInvitesService: invitationService)
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
												premiumCardsService: premiumService,
                                                invitationService: invitationService)
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }
    
    
    // MARK: Appearance setup
    
    func setupAppearance() {
        let segmentFont = UIFont(name: "Roboto-Medium", size: 16) ?? UIFont.systemFont(ofSize: 16)
        UISegmentedControl.appearance().setTitleTextAttributes([NSAttributedStringKey.font: segmentFont], for: .normal)
    }
}
