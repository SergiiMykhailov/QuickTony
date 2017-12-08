//
//  ViewModels.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation

protocol ProgressGenerating {
    var showProgressCallback : ((Bool) -> ())? {get set}
}

protocol AlertGenerating : SuccessAlertGenerating, WarningAlertGenerating {
}

protocol SuccessAlertGenerating {
    var successAlertHandler : ((String) -> ())? {get set}
}

protocol WarningAlertGenerating {
    var warningAlertHandler : ((String) -> ())? {get set}
}

protocol RequiredFieldAlertGenerating {
    var requiredFieldAlertHandler : ((String) -> ())? {get set}
}

protocol CustomAlertGenerating {
    var customAlertHandler : ((String, String) -> ())? {get set}
}


