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
// This is done to make the UIKit use the same object,
// allowing the checking of whether the speech is currently busy
// so we can ignore the next speech and let the current speech finished
var speechSynthesizer = AVSpeechSynthesizer()

struct ContentView: View {
    @State var hideVideoCaptureView = true
    @State private var showScreen = false
    @State private var showSetting = false
    // destination is binded to UIKit representable due to
    // UIKit need to save destination as well when objects are detected & dictated
    // if destination is empty or blank
    // UIKit will use save destination as "Roaming"
    @State private var destination = ""
    
    var body: some View {
        ZStack(alignment: .topLeading) {
            // This section will be the whole screen of main view
            // Top half will be VideoCaptureView or Plain white view if the device is simulator
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
            
            
            // This part is where the buttons on the top left are
            // first button is for showing dashboard screen
            
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
                
                // second button is the showing setting screen
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
        .sheet(isPresented: $showScreen) {
            // sheet to show dashboard
            DashboardScreen()
        }
        .sheet(isPresented: $showSetting) {
            // sheet to show setting
            SettingScreen()
        }
        .onAppear {
            // delaying 2 seconds, just enough for the camera view to load
            // this is done for the purpose of making the app looks
            // a bit nicer (no laggin) when first loaded
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
