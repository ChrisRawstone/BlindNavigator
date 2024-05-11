//
//  NotificationCenter+Extension.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import Foundation
public extension Notification.Name {
    
    private static let app = "BlindNavigator"
    
    static var didUpdateSetting: Notification.Name {
        return .init(rawValue: app + ".didUpdateSetting")
    }
}
