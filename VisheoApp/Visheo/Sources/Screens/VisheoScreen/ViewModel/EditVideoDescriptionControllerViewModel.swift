//
//  EditVideoDescriptionControllerViewModel.swift
//  Visheo
//
//  Created by Ivan on 4/2/18.
//  Copyright (c) 2018 Olearis. All rights reserved.
//
//

import Foundation
protocol EditVideoDescriptionViewModel: class {
    
    var videoDescription : String {get}
    func editionCompleted(withText text: String)
}

final class EditVideoDescriptionControllerViewModel: EditVideoDescriptionViewModel {

    private(set) var videoDescription : String
    private(set) var editSuccessHandler : ((String)->())?
    
    // MARK: - Private properties -
    private(set) weak var router: EditVideoDescriptionRouter?

    // MARK: - Lifecycle -

    init(router: EditVideoDescriptionRouter,
         description: String,
         editSuccessHandler: ((String)->())?){
        self.router = router
        self.videoDescription = description
        self.editSuccessHandler = editSuccessHandler
    }
    
    func editionCompleted(withText text: String) {
        videoDescription = text
        editSuccessHandler?(videoDescription)
    }

}
