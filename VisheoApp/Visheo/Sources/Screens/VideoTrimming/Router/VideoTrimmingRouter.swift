//
//  VideoTrimmingRouter.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/19/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol VideoTrimmingRouter: FlowRouter {
    func goBack()
    func showPreview(with assets: VisheoRenderingAssets)
    func goBackFromEdit(with assets: VisheoRenderingAssets?)
    func showRetake(with assets: VisheoRenderingAssets)
}

class VisheoVideoTrimmingRouter : VideoTrimmingRouter {
    enum SegueList: String, SegueListType {
        case showPreview = "showPreview"
        case showRetake = "showRetake"
    }
    let dependencies: RouterDependencies
    private(set) weak var controller: VideoTrimmingViewController?
    private(set) weak var viewModel: VisheoVideoTrimmingViewModel?
    private let editModeCallback: ((VisheoRenderingAssets)->())?
    
    let assets : VisheoRenderingAssets
    
    public init(dependencies: RouterDependencies, assets: VisheoRenderingAssets, callback: ((VisheoRenderingAssets)->())? = nil) {
        self.dependencies = dependencies
        self.assets = assets
        self.editModeCallback = callback
    }
    
    func start(with viewController: VideoTrimmingViewController, editMode: Bool = false) {
        let vm = VisheoVideoTrimmingViewModel(assets: assets, editMode: editMode)
        viewModel = vm
        vm.router = self
        self.controller = viewController
        viewController.configure(viewModel: vm, router: self)
    }
    
    func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let segueList = SegueList(segue: segue) else {
            return
        }
        switch segueList {
        case .showPreview:
            let previewController = segue.destination as! VisheoPreviewViewController
            let previewRouter = VisheoPreviewRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets)
            previewRouter.start(with: previewController)
        case .showRetake:
            let retakeViewController = segue.destination as! CameraViewController
            let retakeRouter = VisheoCameraRouter(dependencies: dependencies, assets: sender as! VisheoRenderingAssets) {
                self.viewModel?.update(with: $0)
            }
            retakeRouter.start(with: retakeViewController)
        }
    }
}

extension VisheoVideoTrimmingRouter {
    func goBack() {
        controller?.navigationController?.popViewController(animated: true)
    }
    
    func showPreview(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showPreview, sender: assets)
    }
    
    func goBackFromEdit(with assets: VisheoRenderingAssets?) {
        if let assets = assets {
            editModeCallback?(assets)
        }
        controller?.dismiss(animated: true, completion: nil)
    }
    
    func showRetake(with assets: VisheoRenderingAssets) {
        controller?.performSegue(SegueList.showRetake, sender: assets)
    }
}

