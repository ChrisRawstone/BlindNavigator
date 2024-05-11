//
//  UIDevice+extension.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import UIKit

extension UIDevice {
    var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}
