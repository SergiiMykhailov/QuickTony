//
//  PrompterRouter.swift
//  Visheo
//
//  Created by Ivan on 4/30/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

protocol PrompterRouter: FlowRouter {
}

class DefaultPrompterRouter:  PrompterRouter {
    
    var dependencies: RouterDependencies

    private(set) weak var viewModel: PrompterViewModel?
    private(set) weak var controller: UIViewController?

    func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        return true
    }

    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
    }
    
    init(withDependecies dependencies: RouterDependencies) {
        self.dependencies = dependencies
    }

    func start(with controller: PrompterViewController, words: [WordIdea]) {
        self.controller = controller
        let vm = PrompterControllerViewModel(router: self, words: words, appStateService: dependencies.appStateService)
        viewModel = vm
        controller.configure(viewModel: vm, router: self)
    }
}
