//
//  NotificationCenter+Extension.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import Foundation

// Notifcation Name extension to register a name called didUpSetting, which will be used
// to broadcast a refresh on UIKit upon updating value on setting screen on SwiftUI
public extension Notification.Name {
    private static let app = "BlindNavigator"
    
    static var didUpdateSetting: Notification.Name {
        return .init(rawValue: app + ".didUpdateSetting")
    }
}
