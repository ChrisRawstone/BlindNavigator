
# BlindNavigator

https://github.com/ChrisRawstone/BlindNavigator/assets/52676332/083b53db-8900-4a96-9da5-5b24230da612





# Description
A navigation app with real-time object detection for blind people! 

#Github link: https://github.com/ChrisRawstone/BlindNavigator

# Table of Contents
1. [Description](#description)
2. [Getting started](#getting-started)
3. [Arhitecture](#arhitecture)
4. [Structure](#structure)
5. [How to run](#How-to-run)



# Getting started

1. Make sure you have the Xcode installed on your computer.
2. Download the project to your local machine.
3. Open the project files in Xcode.
4. Make sure the yolo models are with the project.
5. Build the project.
6. Once done and succeed, try running the app on a simulator or device


# Architecture
* BlindNavigator uses combination of UIKit and SwiftUI, states in SwiftUI views are in form of local @State and @Binding. 

# Structure 
* "Components": All UIs that represent each screen in the app, They are grouped into sections sometimes for readibility. 
* "Models": Models folder store yolov8m, a pre-trained for object detection 
* "Ultilities": All helpers classes
* "Extension": Store extension class

# How to run 
* If run on simulator:
 1. make sure the Code signing has no issue, uncheck the Automatically Manage Signing. 
 Note: As the simulator does not support camera, the object detection view will not work and will be replaced by a white view instead. Map view should work as expected. Both dashboard and setting screen will be not as relavent.
 
 * If run on device:
 1. make sure the Code signing has a valid provisioning to the device. Try check on Automatically Manage Signing and leave the bundle id the same. Given the device uses the same apple id as the one with Code Signing, the device should be able to run the app.
 Note: The object detection should work as expected as long as the user allow the camera permission.
 
 
