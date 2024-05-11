//
//  Destination.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import Foundation

struct Destination: Codable {
    let location: String // Descriptive location name
    let objects: [String] // Array of captured object names
}
