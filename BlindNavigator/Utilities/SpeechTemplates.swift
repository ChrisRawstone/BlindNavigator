//
//  SpeechTemplates.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import Foundation

// A constant list of speech templates
// this will be used to suffle during each speech
// so the voice appear more natural than just using only one speech
// each line containts {1} that will later on be replaced by objects, using replaceByOccurance in string
let speechTemplates = [
    "Right before you, {1} are present.",
    "Directly ahead, {1} await",
    "Within your immediate view, {1} are present",
    "In front of your position, {1} are within reach.",
    "Just ahead of you, {1} are situated.",
    "Facing you, {1} occupy the space.",
    "There's {1} in front of you",
    "In front of your position, {1} are within reach."
]
