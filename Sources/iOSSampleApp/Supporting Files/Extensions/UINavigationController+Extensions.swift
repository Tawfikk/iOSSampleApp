//
//  UINavigationController+Extensions.swift
//  iOSSampleApp
//
//  Created by Igor Kulman on 05/10/2017.
//  Copyright © 2017 Igor Kulman. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
    func setBackButton() {
        let backButton = UIBarButtonItem()
        backButton.title = L10n.back
        viewControllers.last?.navigationItem.backBarButtonItem = backButton
    }
}
