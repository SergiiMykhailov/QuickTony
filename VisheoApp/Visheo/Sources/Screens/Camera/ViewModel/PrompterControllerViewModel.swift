//
//  PrompterControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/30/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation

protocol PrompterViewModel: class {
    
}

final class PrompterControllerViewModel: PrompterViewModel {

    // MARK: - Private properties -
    private(set) weak var router: PrompterRouter?

    // MARK: - Lifecycle -

    init(router: PrompterRouter) {
        self.router = router
    }

}
