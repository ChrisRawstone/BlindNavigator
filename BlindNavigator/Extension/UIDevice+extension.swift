//
//  UIDevice+extension.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import UIKit

// An extension for checking if the running device is simulator
// This is used to check the device when app trying to access
// camera on when app starts running
// Then we show a placeholder view so the app can be run on simulator
// without crashing

extension UIDevice {
    var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}
