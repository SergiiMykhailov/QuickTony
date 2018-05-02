//
//  PrompterViewController.swift
//  Visheo
//
//  Created by Ivan on 4/30/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

final class PrompterViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: PrompterViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: PrompterViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

    }

}

// MARK: - Router -
extension PrompterViewController {

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        router.prepare(for: segue, sender: sender)
        return super.prepare(for: segue, sender: sender)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if router.shouldPerformSegue(withIdentifier: identifier, sender: sender) == false {
            return false
        }
        return super.shouldPerformSegue(withIdentifier: identifier, sender: sender)
    }

}
