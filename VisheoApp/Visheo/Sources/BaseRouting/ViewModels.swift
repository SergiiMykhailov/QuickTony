//
//  ViewModels.swift
//  Visheo
//
//  Created by Petro Kolesnikov on 11/4/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import Foundation


protocol LongFailableActionViewModel: class {
    var showProgressCallback : ((Bool) -> ())? {get set}
    var warningAlertHandler : ((String) -> ())? {get set}
}
