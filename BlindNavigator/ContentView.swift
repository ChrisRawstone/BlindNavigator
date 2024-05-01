//
//  ContentView.swift
//  BlindNavigator
//
//  Created by chuan on 30/4/2024.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
          //  HomeScreen()
            
            VideoCaptureView()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
}
