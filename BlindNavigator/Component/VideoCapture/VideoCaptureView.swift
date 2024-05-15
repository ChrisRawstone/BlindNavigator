//
//  VideoCaptureView.swift
//  assessment2
//
//  Created by chuan on 30/4/2024.
//

import SwiftUI

struct VideoCaptureView: UIViewControllerRepresentable {
    // destination string is bind to uiViewController, whenever there is a new value
    // the viewcontroller current destination will be updated too via func updateUIViewController()
    
    @Binding var destination: String
    
    typealias UIViewControllerType = VideoCaptureViewController
    
    // returning an uiviewcontroller of type VideoCaptureViewController
    func makeUIViewController(context: Context) -> VideoCaptureViewController {
        let controller = VideoCaptureViewController.storyboardInstance()
        return controller
    }
    
    // bind destination value  to video capture view
    func updateUIViewController(_ uiViewController: VideoCaptureViewController, context: Context) {
        uiViewController.currentDestination = destination
    }
}
