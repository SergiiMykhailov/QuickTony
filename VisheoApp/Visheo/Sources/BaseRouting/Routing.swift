//
//  Routing.swift
//
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol FlowRouter: class {
    var dependencies: RouterDependencies { get }
    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool
    func prepare(for segue: UIStoryboardSegue, sender: Any?)
}

protocol RouterProxy {
    var router: FlowRouter! { get }
}

extension FlowRouter {
    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }
}

struct RouterDependencies {
    let appStateService : AppStateService
    let appPermissionsService : AppPermissionsService
    let authorizationService : AuthorizationService
    let userInfoProvider : UserInfoProvider
    let userInputValidator : UserInputValidator
    let occasionsListService : OccasionsListService
    let visheosListService : VisheosListService
    
    let purchasesInfo: UserPurchasesInfo
    let renderingService : RenderingService
    let creationService : CreationService
	let soundtracksService: SoundtracksService;
	let userNotificationsService: UserNotificationsService;
	let loggingService: EventLoggingService
	let feedbackService: FeedbackService;

    let routerAssembly: RouterAssembly
    let visheosCache : VisheosCache
    
    let premiumCardsService: PremiumCardsService
}
