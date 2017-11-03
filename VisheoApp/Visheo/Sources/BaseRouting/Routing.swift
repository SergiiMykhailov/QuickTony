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
    let authorizationService : AuthorizationService
}
