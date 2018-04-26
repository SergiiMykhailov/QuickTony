//
//  CoverOnboardingScreenRouter.swift
//  Visheo
//
//  Created by Ivan on 3/29/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol CoverOnboardingScreenRouter: FlowRouter {
    func showSelectCover()
}

class VisheoCoverOnboardingScreenRouter:  CoverOnboardingScreenRouter {
    var dependencies: RouterDependencies
    
    enum SegueList: String, SegueListType {
        case showOccasion = "showOccasion"
    }

    private(set) var occasion: OccasionRecord
    
    private(set) weak var viewModel: CoverOnboardingScreenViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueList = SegueList(segue: segue) else {
            return
        }

        switch segueList {
            case .showOccasion:
                let selectCoverController = segue.destination as! SelectCoverViewController
                let selectCoverRouter = VisheoSelectCoverRouter(dependencies: dependencies, occasion: sender as! OccasionRecord)
                selectCoverRouter.start(with: selectCoverController)
        }
    }

    func showSelectCover() {
        controller?.performSegue(SegueList.showOccasion, sender: occasion)
    }
    
    init(dependencies: RouterDependencies, occasion: OccasionRecord) {
        self.dependencies = dependencies
        self.occasion = occasion
    }

    func start(with controller: CoverOnboardingScreenViewController) {
        self.controller = controller
        let vm = CoverOnboardingScreenControllerViewModel(appStateService: dependencies.appStateService,
                                                          router: self)
        viewModel = vm
        controller.configure(viewModel: vm, router: self)
    }
}
