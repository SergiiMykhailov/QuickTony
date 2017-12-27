//
//  TipsViewModel.swift
//  Visheo
//
//  Created by Nikita Ivanchikov on 12/27/17.
//  Copyright © 2017 Olearis. All rights reserved.
//

import UIKit

protocol TipsViewModel: class {

}

class VisheoTipsViewModel: TipsViewModel {
	weak var router: TipsRouter?
}
