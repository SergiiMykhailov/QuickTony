//
//  EditVideoDescriptionViewController.swift
//  Visheo
//
//  Created by Ivan on 4/2/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import UIKit

final class EditVideoDescriptionViewController: UIViewController {

    struct Constants {
        static let stringLenght = 60
    }
    
    // MARK: - Public properties -

    private(set) var viewModel: EditVideoDescriptionViewModel!
    private(set) var router: FlowRouter!

    // MARK: - Configuration -

    func configure(viewModel: EditVideoDescriptionViewModel, router: FlowRouter) {
        self.viewModel = viewModel
        self.router    = router
    }

    // MARK: - Lifecycle -

    override func viewDidLoad() {
        super.viewDidLoad()

        descriptionField.text = viewModel.videoDescription
        descriptionField.delegate = self;
    }

    // MARK: Outlets
    @IBOutlet weak var descriptionField: UITextField!
    @IBOutlet weak var saveButton: UIButton!
    
    @IBAction func savePressed(_ sender: Any) {
        view.endEditing(true)
        viewModel.editionCompleted(withText: descriptionField.text ?? "")
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func backPressed(_ sender: Any) {
        view.endEditing(true)
        navigationController?.popViewController(animated: true)
    }
}

// MARK: - Router -
extension EditVideoDescriptionViewController {

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

extension EditVideoDescriptionViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        savePressed(textField);
        return true;
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let nsString = textField.text as NSString?
        let count = nsString?.replacingCharacters(in: range, with: string).count ?? 0
        return string == "" || count < Constants.stringLenght
    }
}
