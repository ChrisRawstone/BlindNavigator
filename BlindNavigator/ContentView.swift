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
    @State private var showSetting = false
    @State private var destination = ""
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack {
                ZStack {
                    Color.white
                
                    if UIDevice.current.isSimulator {
                        Text("Video view is currently not available on simulator")
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    else {
                        if hideVideoCaptureView == false {
                            VideoCaptureView(destination: $destination)
                        }
                        else {
                            ProgressView()
                        }
                    }
                }
                
                GPSContentView(searchedDestination: $destination)
            }
            
            VStack(spacing: 0) {
                Button {
                    showScreen = true
                } label: {
                   Image(systemName: "info.circle.fill")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .tint(.gray)
                }
                .padding()
                
                Button {
                    showSetting = true
                } label: {
                   Image(systemName: "gear")
                        .resizable()
                        .scaledToFill()
                        .frame(width: 30, height: 30)
                        .tint(.gray)
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showScreen, content: {
            DashboardScreen()
        })
        
        .sheet(isPresented: $showSetting) {
            SettingScreen()
        }
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
