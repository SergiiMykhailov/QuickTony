//
//  RootViewControllerSegue
//  Created by Petro Kolesnikov on 9/10/15.
//  Copyright © 2015 Olearis. All rights reserved.
//

import Foundation
import UIKit

public class RootViewControllerSegue: UIStoryboardSegue {
    
    public override func perform() {
        if let appDelegate = UIApplication.shared.delegate {
            appDelegate.window??.rootViewController = self.destination
        }
    }
}
