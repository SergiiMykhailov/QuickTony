//
//  InviteFriendsViewController.swift
//  Visheo
//
//  Created by Ivan on 4/10/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit
import TwitterKit
import FBSDKShareKit

final class InviteFriendsViewController: UIViewController {

    // MARK: - Public properties -

    private(set) var viewModel: InviteFriendsViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: InviteFriendsViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        linkLable.text = viewModel.inviteLink
    }

    @IBOutlet weak var linkLable: UILabel!
    
    @IBAction func menuPressed(_ sender: Any) {
        viewModel.showMenu()
    }
    
    @IBAction func longPressGesture(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if (gestureRecognizer.state == .began) {
            copyToClipboard()
        }
    }
    
    @IBAction func copyPressed(_ sender: Any) {
        copyToClipboard()
    }
    
    @IBAction func facebookPressed(_ sender: Any) {
        let content = FBSDKShareLinkContent()
        content.contentURL = viewModel.inviteUrl;
        
        let dialog = FBSDKShareDialog()
        dialog.fromViewController = self
        dialog.shareContent = content
        dialog.mode = .feedWeb
        dialog.delegate = self
        
        dialog.show()
    }
    
    @IBAction func twitterPressed(_ sender: Any) {
        if (TWTRTwitter.sharedInstance().sessionStore.hasLoggedInUsers()) {
            self.showTwitter()
        } else {
            TWTRTwitter.sharedInstance().logIn { [weak self] session, error in
                if session != nil { // Log in succeeded
                    self?.showTwitter()
                } else {
                    self?.showWarningAlertWithText(text: error?.localizedDescription ?? "")
                }
            }
        }
    }
    
    func showTwitter() {
        let composer = TWTRComposer()
        composer.setURL(viewModel.inviteUrl)
        composer.setText("TEST")
        composer.show(from: self) { [weak self] in
            if ($0 == .done) {
                self?.viewModel.trackTwitterShared()
            }
        }
    }
    
    @IBAction func sharePressed(_ sender: Any) {
        if let link = viewModel.inviteLink, let inviteLink = URL(string: link) {
            let interaction = UIActivityViewController(activityItems: [inviteLink], applicationActivities: nil)
            interaction.completionWithItemsHandler = { [weak self] _, completed, _, _ in
                if completed { self?.viewModel.trackLinkShared() }
            }
            present(interaction, animated: true, completion: nil)
        }
    }
    
    func copyToClipboard() {
        if let link = viewModel.inviteLink {
            UIPasteboard.general.string = link
            showToast(message: NSLocalizedString("Invite link was copied", comment: "Invite link was copied to clipboard message"))
            viewModel.trackLinkCopied();
        }
    }
    
}

// MARK: - Router -
extension InviteFriendsViewController {

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

extension InviteFriendsViewController: FBSDKSharingDelegate {
    func sharer(_ sharer: FBSDKSharing!, didCompleteWithResults results: [AnyHashable : Any]!) {
        viewModel.trackFacebookShared()
    }
    
    func sharer(_ sharer: FBSDKSharing!, didFailWithError error: Error!) {
        showWarningAlertWithText(text: error.localizedDescription)
    }
    
    func sharerDidCancel(_ sharer: FBSDKSharing!) {
    }
}

extension InviteFriendsViewController: InviteFriendsViewModelDelegate {

    func refreshUI() {
        linkLable.text = viewModel.inviteLink
    }

}
