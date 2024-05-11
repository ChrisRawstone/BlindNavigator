//
//  SettingScreen.swift
//  BlindNavigator
//
//  Created by chuan on 11/5/2024.
//

import SwiftUI

struct SettingScreen: View {
    @AppStorage("numberOfObjects") var numberOfObjects = 3.0
    @AppStorage("confidence") var confidence: Double = 0.05
    @AppStorage("threshold") var iouThreshold: Double = 0.45
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack {
            Text("Setting")
                .font(.headline)
            
            Spacer().frame(height: 40)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Number of objects: \(Int(numberOfObjects))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
               
                Slider(value: $numberOfObjects, in: 1.0...10.0, step: 1)
            }
            
            Spacer().frame(height: 16)
            
            VStack(spacing: 0) {
                HStack {
                    Text("Confidence level: \(String(format: "Angle: %.2f", confidence))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
              
                Slider(value: $confidence, in: 0.00...1.00, step: 0.01)
            }
            
            Spacer().frame(height: 16)
           
            VStack(spacing: 0) {
                HStack {
                    Text("Confidence level: \(String(format: "Angle: %.2f", iouThreshold))")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                Slider(value: $iouThreshold, in: 0.00...1.00, step: 0.01)
            }
            Spacer()
            
            Button {
                NotificationCenter.default.post(name: .didUpdateSetting, object: nil)
                dismiss()
            } label: {
                Text("Save")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(height: 56)
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
    }
}

#Preview {
    SettingScreen()
}
