//
//  ContentView.swift
//  BlindNavigator
//
//  Created by chuan on 30/4/2024.
//

import SwiftUI
import AVFAudio
import MapKit

//global speechSynthesizer
var speechSynthesizer = AVSpeechSynthesizer()

extension CLLocationCoordinate2D {
    static var start = CLLocationCoordinate2D(latitude: 49.7071, longitude: 0.2064)
    static var end = CLLocationCoordinate2D(latitude: 49.734, longitude: 0.222)
}

struct ContentView: View {
    @State var hideVideoCaptureView = true
    @State private var showScreen = false
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                ZStack {
                    Color.white
                
                    if hideVideoCaptureView == false {
                        VideoCaptureView()
                    }
                    else {
                        ProgressView()
                    }
                }
                
                GPSContentView()
            }
            
            Button {
                showScreen = true
            } label: {
               Image(systemName: "xmark.circle.fill")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 30, height: 30)
            }
            .padding()
        }
        .sheet(isPresented: $showScreen, content: {
            Text("Hello")
        })
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                hideVideoCaptureView = false
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        
    }
}

#Preview {
    ContentView()
}
