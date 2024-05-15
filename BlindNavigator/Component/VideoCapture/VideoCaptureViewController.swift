//
//  VideoCaptureViewController.swift
//  assessment2
//
//  Created by chuan on 30/4/2024.
//

import AVFoundation
import CoreMedia
import CoreML
import UIKit
import Vision

var mlModel = try! yolov8m(configuration: .init()).model

class VideoCaptureViewController: UIViewController {
    @IBOutlet var videoPreview: UIView!
    @IBOutlet var View0: UIView!
    
    @IBOutlet weak var labelVersion: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    let selection = UISelectionFeedbackGenerator()
    var detector = try! VNCoreMLModel(for: mlModel)
    var session: AVCaptureSession!
    var videoCapture: VideoCapture!
    var currentBuffer: CVPixelBuffer?
    var framesDone = 0
    var t0 = 0.0  // inference start
    var t1 = 0.0  // inference dt
    var t2 = 0.0  // inference dt smoothed
    var t3 = CACurrentMediaTime()  // FPS start
    var t4 = 0.0  // FPS dt smoothed
    
    var currentDestination: String = "" { didSet { print("current destination is \(currentDestination)") } }
    
    // last appeared objects hold appeared objects for the next speech
    // doing this allow the speech to only described the lastest objects only
    var lastAppearedObjects: [String] = []
    
    // this numberOfObjects will hold the number of objects detection allow by the setting
    private var numberOfObjects: Double = 10
    
    // timer is used for speech, every 10 seconds
    var timer: Timer?
    
    // userDefault is used to save objects that are described by the speech
    private let userDefault = UserDefaults.standard
    
    // Developer mode
    let developerMode = UserDefaults.standard.bool(forKey: "developer_mode")   // developer mode selected in settings
    let save_detections = false  // write every detection to detections.txt
    let save_frames = false  // write every frame to frames.txt
    
    lazy var visionRequest: VNCoreMLRequest = {
        let request = VNCoreMLRequest(model: detector, completionHandler: {
            [weak self] request, error in
            self?.processObservations(for: request, error: error)
        })
        // NOTE: BoundingBoxView object scaling depends on request.imageCropAndScaleOption https://developer.apple.com/documentation/vision/vnimagecropandscaleoption
        request.imageCropAndScaleOption = .scaleFill  // .scaleFit, .scaleFill, .centerCrop
        return request
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setDefaultsValueIfNeeded()
        setUpBoundingBoxViews()
        startVideo()
        setModel()
        timer = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(describeObjectsIfNeeded), userInfo: nil, repeats: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(refresh), name: .didUpdateSetting, object: nil)
    }
    
    // This function is meant for setting the default setting
    // if that has not been before
    func setDefaultsValueIfNeeded() {
        let numbObjects = userDefault.double(forKey: "numberOfObjects")
        let confidence = userDefault.double(forKey: "confidence")
        let iouThreshold = userDefault.double(forKey: "threshold")
        
        if numbObjects == 0 {
            userDefault.setValue(10.0, forKey: "numberOfObjects")
        }
        if confidence == 0 {
            userDefault.setValue(0.28, forKey: "confidence")
        }
        if iouThreshold == 0 {
            userDefault.setValue(0.15, forKey: "threshold")
        }
    }
    
    @objc func refresh() {
        let numbObjects = userDefault.double(forKey: "numberOfObjects")
        let confidence = userDefault.double(forKey: "confidence")
        let iouThreshold = userDefault.double(forKey: "threshold")
        self.numberOfObjects = numbObjects
        detector.featureProvider = ThresholdProvider(iouThreshold: iouThreshold, confidenceThreshold: confidence)
        
        print("number \(numbObjects)")
        print("confidence \(confidence)")
        print("threshold \(iouThreshold)")
    }
    
    // MARK: - save destination
    func saveDestination(location: String, objects: [String]) {
        do{
            var destinations: [Destination] = []
            
            // check if there are existing dashboard in user default
            if let savedData = userDefault.object(forKey: "dashboard") as? Data {
                // decode the data into an array of object Destination
                destinations = try JSONDecoder().decode([Destination].self, from: savedData)
            }
            
            // check if the location that save has existed in the list
            if let existingIndex = destinations.firstIndex(where: { $0.location == location }) {
                // if exist, only append the objects to the item
               let exsitingObjects = destinations[existingIndex].objects
                destinations[existingIndex].objects = exsitingObjects + objects
            } else {
                // if the location doesnot exist in saved data
                // add the desitnation into the list, along with objects
                let newDestination = Destination(location: location, objects: objects)
                destinations.append(newDestination)
            }
            
            // encoding the temparory destinations list
            let encodedData = try JSONEncoder().encode(destinations)
            
            // now set the encoded destination list into the user default to save the data.
            userDefault.set(encodedData, forKey: "dashboard")
            
            print("save destination successfully \(destinations.count) \(destinations)")
        } catch {
            print("Couldn't save destination to user default")
        }
    }
    
    // function to describe objects using speech
    
    @objc func describeObjectsIfNeeded() {
        // get objects from last appeared objects and take only amount of that setting
        
        let objects = lastAppearedObjects.unique.prefix(Int(numberOfObjects))
        
        // save the destination before speech, if destination is empty, add "Roaming" as destination
        saveDestination(location:  currentDestination.isEmpty ? "Roaming" : currentDestination, objects: Array(objects))
        
        // join objects using ", " so the speech can speak the objects clearly
        // otherwise the speech not say the objects correctly
        let text = objects.joined(separator: ", ")
        
        // randomize the speech from speech templates
        let randomizedText = speechTemplates.randomElement()?.replacingOccurrences(of: "{1}", with: text)
        
        // initialize speech utterance
        // setting language and rate
        let utterance = AVSpeechUtterance(string: randomizedText ?? "")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.4
        
        // check if the speech is busy,
        // we ignore the speech and wait until next time the speech is available
        if speechSynthesizer.isSpeaking == false {
            speechSynthesizer.speak(utterance)
        }
        else {
            print("Objects are not desribed due to speechSyn is busy")
        }
        
        // remove last appeared objects so new one can be observed
        lastAppearedObjects.removeAll()
    }
    
    // setting up model for YOLO
    func setModel() {
        /// VNCoreMLModel
        let numbObjects = userDefault.double(forKey: "numberOfObjects")
        let confidence = userDefault.double(forKey: "confidence")
        let iouThreshold = userDefault.double(forKey: "threshold")
        self.numberOfObjects = numbObjects
        detector = try! VNCoreMLModel(for: mlModel)
        detector.featureProvider = ThresholdProvider(iouThreshold: iouThreshold, confidenceThreshold: confidence)
        
        /// VNCoreMLRequest
        let request = VNCoreMLRequest(model: detector, completionHandler: { [weak self] request, error in
            self?.processObservations(for: request, error: error)
        })
        request.imageCropAndScaleOption = .scaleFill  // .scaleFit, .scaleFill, .centerCrop
        visionRequest = request
        t2 = 0.0 // inference dt smoothed
        t3 = CACurrentMediaTime()  // FPS start
        t4 = 0.0  // FPS dt smoothed
    }

    let maxBoundingBoxViews = 100
    var boundingBoxViews = [BoundingBoxView]()
    var colors: [String: UIColor] = [:]
    
    func setUpBoundingBoxViews() {
        // Ensure all bounding box views are initialized up to the maximum allowed.
        while boundingBoxViews.count < maxBoundingBoxViews {
            boundingBoxViews.append(BoundingBoxView())
        }
        
        // Retrieve class labels directly from the CoreML model's class labels, if available.
        guard let classLabels = mlModel.modelDescription.classLabels as? [String] else {
            fatalError("Class labels are missing from the model description")
        }
        
        // Assign random colors to the classes.
        for label in classLabels {
            if colors[label] == nil {  // if key not in dict
                colors[label] = UIColor(red: CGFloat.random(in: 0...1),
                                        green: CGFloat.random(in: 0...1),
                                        blue: CGFloat.random(in: 0...1),
                                        alpha: 0.6)
            }
        }
    }
    
    func startVideo() {
        videoCapture = VideoCapture()
        videoCapture.delegate = self
        
        videoCapture.setUp(sessionPreset: .photo) { success in
            // .hd4K3840x2160 or .photo (4032x3024)  Warning: 4k may not work on all devices i.e. 2019 iPod
            if success {
                // Add the video preview into the UI.
                if let previewLayer = self.videoCapture.previewLayer {
                    self.videoPreview.layer.addSublayer(previewLayer)
                    self.videoCapture.previewLayer?.frame = self.videoPreview.bounds  // resize preview layer
                }
                
                // Add the bounding box layers to the UI, on top of the video preview.
                for box in self.boundingBoxViews {
                    box.addToLayer(self.videoPreview.layer)
                }
                
                // Once everything is set up, we can start capturing live video.
                self.videoCapture.start()
            }
        }
    }
    
    func predict(sampleBuffer: CMSampleBuffer) {
        if currentBuffer == nil, let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) {
            currentBuffer = pixelBuffer
            
            /// - Tag: MappingOrientation
            // The frame is always oriented based on the camera sensor,
            // so in most cases Vision needs to rotate it for the model to work as expected.
            let imageOrientation: CGImagePropertyOrientation
            switch UIDevice.current.orientation {
            case .portrait:
                imageOrientation = .up
            case .portraitUpsideDown:
                imageOrientation = .down
            case .landscapeLeft:
                imageOrientation = .left
            case .landscapeRight:
                imageOrientation = .right
            case .unknown:
                print("The device orientation is unknown, the predictions may be affected")
                fallthrough
            default:
                imageOrientation = .up
            }
            
            // Invoke a VNRequestHandler with that image
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: imageOrientation, options: [:])
            if UIDevice.current.orientation != .faceUp {  // stop if placed down on a table
                t0 = CACurrentMediaTime()  // inference start
                do {
                    try handler.perform([visionRequest])
                } catch {
                    print(error)
                }
                t1 = CACurrentMediaTime() - t0  // inference dt
            }
            
            currentBuffer = nil
        }
    }
    
    func processObservations(for request: VNRequest, error: Error?) {
        DispatchQueue.main.async {
            if let results = request.results as? [VNRecognizedObjectObservation] {
                self.show(predictions: results)
            } else {
                self.show(predictions: [])
            }
            
            // Measure FPS
            if self.t1 < 10.0 {  // valid dt
                self.t2 = self.t1 * 0.05 + self.t2 * 0.95  // smoothed inference time
            }
            self.t4 = (CACurrentMediaTime() - self.t3) * 0.05 + self.t4 * 0.95  // smoothedb
            self.t3 = CACurrentMediaTime()
            
        }
    }
    
    // Save text file
    func saveText(text: String, file: String = "saved.txt") {
        if let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileURL = dir.appendingPathComponent(file)
            
            // Writing
            do {  // Append to file if it exists
                let fileHandle = try FileHandle(forWritingTo: fileURL)
                fileHandle.seekToEndOfFile()
                fileHandle.write(text.data(using: .utf8)!)
                fileHandle.closeFile()
            } catch {  // Create new file and write
                do {
                    try text.write(to: fileURL, atomically: false, encoding: .utf8)
                } catch {
                    print("no file written")
                }
            }
            
            // Reading
            // do {let text2 = try String(contentsOf: fileURL, encoding: .utf8)} catch {/* error handling here */}
        }
    }
    
    // Save image file
    func saveImage() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        let fileURL = dir!.appendingPathComponent("saved.jpg")
        let image = UIImage(named: "ultralytics_yolo_logotype.png")
        FileManager.default.createFile(atPath: fileURL.path, contents: image!.jpegData(compressionQuality: 0.5), attributes: nil)
    }
    
    // Return hard drive space (GB)
    func freeSpace() -> Double {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() as String)
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            return Double(values.volumeAvailableCapacityForImportantUsage!) / 1E9   // Bytes to GB
        } catch {
            print("Error retrieving storage capacity: \(error.localizedDescription)")
        }
        return 0
    }
    
    // Return RAM usage (GB)
    func memoryUsage() -> Double {
        var taskInfo = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if kerr == KERN_SUCCESS {
            return Double(taskInfo.resident_size) / 1E9   // Bytes to GB
        } else {
            return 0
        }
    }
    
    func show(predictions: [VNRecognizedObjectObservation]) {
        let width = videoPreview.bounds.width  // 375 pix
        let height = videoPreview.bounds.height  // 812 pix
        var str = ""
        
        // ratio = videoPreview AR divided by sessionPreset AR
        var ratio: CGFloat = 1.0
        if videoCapture.captureSession.sessionPreset == .photo {
            ratio = (height / width) / (4.0 / 3.0)  // .photo
        } else {
            ratio = (height / width) / (16.0 / 9.0)  // .hd4K3840x2160, .hd1920x1080, .hd1280x720 etc.
        }
        
        // date
        let date = Date()
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let seconds = calendar.component(.second, from: date)
        let nanoseconds = calendar.component(.nanosecond, from: date)
        let sec_day = Double(hour) * 3600.0 + Double(minutes) * 60.0 + Double(seconds) + Double(nanoseconds) / 1E9  // seconds in the day
        
        
        for i in 0..<boundingBoxViews.count {
            if i < predictions.count && i < Int(numberOfObjects) {
                let prediction = predictions[i]
                
                
                var rect = prediction.boundingBox  // normalized xywh, origin lower left
                switch UIDevice.current.orientation {
                case .portraitUpsideDown:
                    rect = CGRect(x: 1.0 - rect.origin.x - rect.width,
                                  y: 1.0 - rect.origin.y - rect.height,
                                  width: rect.width,
                                  height: rect.height)
                case .landscapeLeft:
                    rect = CGRect(x: rect.origin.y,
                                  y: 1.0 - rect.origin.x - rect.width,
                                  width: rect.height,
                                  height: rect.width)
                case .landscapeRight:
                    rect = CGRect(x: 1.0 - rect.origin.y - rect.height,
                                  y: rect.origin.x,
                                  width: rect.height,
                                  height: rect.width)
                case .unknown:
                    print("The device orientation is unknown, the predictions may be affected")
                    fallthrough
                default: break
                }
                
                if ratio >= 1 { // iPhone ratio = 1.218
                    let offset = (1 - ratio) * (0.5 - rect.minX)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: offset, y: -1)
                    rect = rect.applying(transform)
                    rect.size.width *= ratio
                } else { // iPad ratio = 0.75
                    let offset = (ratio - 1) * (0.5 - rect.maxY)
                    let transform = CGAffineTransform(scaleX: 1, y: -1).translatedBy(x: 0, y: offset - 1)
                    rect = rect.applying(transform)
                    rect.size.height /= ratio
                }
                
                // Scale normalized to pixels [375, 812] [width, height]
                rect = VNImageRectForNormalizedRect(rect, Int(width), Int(height))
                
                // The labels array is a list of VNClassificationObservation objects,
                // with the highest scoring class first in the list.
                let bestClass = prediction.labels[0].identifier
                let confidence = prediction.labels[0].confidence
                // print(confidence, rect)  // debug (confidence, xywh) with xywh origin top left (pixels)
                lastAppearedObjects.append(bestClass)
                
                // Show the bounding box.
                boundingBoxViews[i].show(frame: rect,
                                         label: String(format: "%@ %.1f", bestClass, confidence * 100),
                                         color: colors[bestClass] ?? UIColor.white,
                                         alpha: CGFloat((confidence - 0.2) / (1.0 - 0.2) * 0.9))  // alpha 0 (transparent) to 1 (opaque) for conf threshold 0.2 to 1.0)
                
                if developerMode {
                    // Write
                    if save_detections {
                        str += String(format: "%.3f %.3f %.3f %@ %.2f %.1f %.1f %.1f %.1f\n",
                                      sec_day, freeSpace(), UIDevice.current.batteryLevel, bestClass, confidence,
                                      rect.origin.x, rect.origin.y, rect.size.width, rect.size.height)
                    }
                    
                    // Action trigger upon detection
                    // if false {
                    //     if (bestClass == "car") {  // "cell phone", "car", "person"
                    //         self.takePhoto(nil)
                    //         // self.pauseButton(nil)
                    //         sleep(2)
                    //     }
                    // }
                }
            } else {
                boundingBoxViews[i].hide()
            }
        }
        
        // Write
        if developerMode {
            if save_detections {
                saveText(text: str, file: "detections.txt")  // Write stats for each detection
            }
            if save_frames {
                str = String(format: "%.3f %.3f %.3f %.3f %.1f %.1f %.1f\n",
                             sec_day, freeSpace(), memoryUsage(), UIDevice.current.batteryLevel,
                             self.t1 * 1000, self.t2 * 1000, 1 / self.t4)
                saveText(text: str, file: "frames.txt")  // Write stats for each image
            }
        }
    }
    
    // Pinch to Zoom Start ---------------------------------------------------------------------------------------------
    let minimumZoom: CGFloat = 1.0
    let maximumZoom: CGFloat = 10.0
    var lastZoomFactor: CGFloat = 1.0
    
    @IBAction func pinch(_ pinch: UIPinchGestureRecognizer) {
        let device = videoCapture.captureDevice
        
        // Return zoom value between the minimum and maximum zoom values
        func minMaxZoom(_ factor: CGFloat) -> CGFloat {
            return min(min(max(factor, minimumZoom), maximumZoom), device.activeFormat.videoMaxZoomFactor)
        }
        
        func update(scale factor: CGFloat) {
            do {
                try device.lockForConfiguration()
                defer {
                    device.unlockForConfiguration()
                }
                device.videoZoomFactor = factor
            } catch {
                print("\(error.localizedDescription)")
            }
        }
        
        let newScaleFactor = minMaxZoom(pinch.scale * lastZoomFactor)
        switch pinch.state {
        case .began: fallthrough
        case .changed:
            update(scale: newScaleFactor)
        case .ended:
            lastZoomFactor = minMaxZoom(newScaleFactor)
            update(scale: lastZoomFactor)
        default: break
        }
    }  // Pinch to Zoom Start ------------------------------------------------------------------------------------------
}  // ViewController class End

extension VideoCaptureViewController: VideoCaptureDelegate {
    func videoCapture(_ capture: VideoCapture, didCaptureVideoFrame sampleBuffer: CMSampleBuffer) {
        predict(sampleBuffer: sampleBuffer)
    }
}

// Programmatically save image
extension VideoCaptureViewController: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        if let error = error {
            print("error occurred : \(error.localizedDescription)")
        }
        if let dataImage = photo.fileDataRepresentation() {
            print(UIImage(data: dataImage)?.size as Any)
            let dataProvider = CGDataProvider(data: dataImage as CFData)
            let cgImageRef: CGImage! = CGImage(jpegDataProviderSource: dataProvider!, decode: nil, shouldInterpolate: true, intent: .defaultIntent)
            let image = UIImage(cgImage: cgImageRef, scale: 0.5, orientation: UIImage.Orientation.right)
            
            // Save to camera roll
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil);
        } else {
            print("AVCapturePhotoCaptureDelegate Error")
        }
    }
}

extension UIViewController {
    class func storyboardInstance() -> Self {
        return storyboardInstance(type: self)
    }
    
    private class func storyboardInstance<T>(type: T.Type) -> T {
        let controllerName = String(describing: self)
        let vc = UIStoryboard(name: controllerName, bundle: nil).instantiateInitialViewController()
        return vc as! T
    }
}

extension Array where Element: Equatable {
    var unique: [Element] {
        var uniqueValues: [Element] = []
        forEach { item in
            guard !uniqueValues.contains(item) else { return }
            uniqueValues.append(item)
        }
        return uniqueValues
    }
}
