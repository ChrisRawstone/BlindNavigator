//
//  Destination.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import Foundation

// Destination struct
struct Destination: Codable {
    let location: String // Descriptive location name
    var objects: [String] // Array of captured object names
}
