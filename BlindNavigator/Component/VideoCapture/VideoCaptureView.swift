//
//  VideoCaptureView.swift
//  assessment2
//
//  Created by chuan on 30/4/2024.
//

import SwiftUI

struct VideoCaptureView: UIViewControllerRepresentable {
    typealias UIViewControllerType = VideoCaptureViewController
    
    func makeUIViewController(context: Context) -> VideoCaptureViewController {
        let controller = VideoCaptureViewController.storyboardInstance()
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: VideoCaptureViewController, context: Context) {
        
    }
}
