//
//  RouterAsembly.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/30/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit
import LGSideMenuController

protocol RouterAssembly {
    func assembleMainScreen(on destination: UIViewController, with dependencies: RouterDependencies)
}

class VisheoRouterAssembly: RouterAssembly {
    func assembleMainScreen(on destination: UIViewController, with dependencies: RouterDependencies) {
        let sideController = destination as! LGSideMenuController
        
        let mainScreenController = (sideController.rootViewController as! UINavigationController).viewControllers[0] as! ChooseOccasionViewController
        let router = VisheoChooseOccasionRouter(dependencies: dependencies)
        router.start(with: mainScreenController)
        
        let menuController = sideController.leftViewController as! MenuViewController
        let menuRouter = VisheoMenuRouter(dependencies: dependencies)
        menuRouter.start(with: menuController)
    }
}
