import SwiftUI
import MapKit
import AVFoundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var currentLocation: CLLocationCoordinate2D?
    @Published var directions: [MKRoute.Step] = []

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        currentLocation = location.coordinate
    }

    func getDirections(to destination: MKMapItem) {
        guard let currentLocation = currentLocation else { return }
        let sourcePlacemark = MKPlacemark(coordinate: currentLocation)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { [weak self] (response, error) in
            guard let self = self, let response = response else { return }
            if let route = response.routes.first {
                self.directions = route.steps
                for step in route.steps {
                    self.speak(step: step)
                }
            }
        }
    }
    
    private func speak(step: MKRoute.Step) {
        let instruction = "In \(step.distance) meters, \(step.instructions)"
        let speechUtterance = AVSpeechUtterance(string: instruction)
        speechSynthesizer.speak(speechUtterance)
    }
}

struct GPSContentView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var searchText = ""
    @Binding var searchedDestination: String
    @State private var route: MKRoute?
    @State private var postion: MapCameraPosition = .userLocation(followsHeading: true, fallback: .automatic)

    var body: some View {
        NavigationView {
            VStack {
                TextField("Search for places", text: $searchText, onCommit: search)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()
                
                Map(position: $postion) {
                    if let route {
                                  MapPolyline(route.polyline)
                                      .stroke(.blue, lineWidth: 8)
                              }
                }
                
                Spacer()
            }
            .navigationBarTitle("Map Directions")
        }
    }

    private func search() {
        guard let currentLocation = locationManager.currentLocation else { return }
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = searchText
        request.region = MKCoordinateRegion(center: currentLocation, span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05))
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let mapItem = response?.mapItems.first else { return }
            self.fetchDirection(to: mapItem)
        }
    }

    private func fetchDirection(to destination: MKMapItem) {
        guard let currentLocation = locationManager.currentLocation else { return }
        let sourcePlacemark = MKPlacemark(coordinate: currentLocation)
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destination
        directionsRequest.transportType = .automobile
        
        let directions = MKDirections(request: directionsRequest)
        directions.calculate { (response, error) in
            if let route = response?.routes.first {
                self.route = route
                searchedDestination = searchText
                let steps = route.steps
                // Start from
                if steps.count > 0 {
                    for (index, step) in steps.dropFirst().enumerated() {
                        // Speak "and" before each step except the last one
                        if index < steps.dropFirst().count - 1 {
                            self.speak(step: step)
                            let speechUtterance = AVSpeechUtterance(string: "and afterwards")
                            speechSynthesizer.speak(speechUtterance)
                        } else {
                            self.speak(step: step)
                        }
                    }
                }
            }
        }

    }
    func truncateToNearestTen(_ value: Double) -> Int {
        let roundedValue = round(value / 10) * 10
        return Int(roundedValue)
    }

    private func speak(step: MKRoute.Step) {
        let instruction = "In \(truncateToNearestTen(step.distance)) meters, \(step.instructions)"
        let speechUtterance = AVSpeechUtterance(string: instruction)
        speechSynthesizer.speak(speechUtterance)
    }
}
