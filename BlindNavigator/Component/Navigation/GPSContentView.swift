import SwiftUI
import MapKit

struct GPSContentView: View {
    @State private var directions: [String] = []
    @State private var showDirections = false
    @EnvironmentObject var locationManager: LocationManager

    var body: some View {
        VStack {
            MapView(directions: $directions)
                .environmentObject(locationManager)

            HStack {
                Button(action: {
                    locationManager.zoomIn()
                }, label: {
                    Text("Zoom In")
                })
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())

                Button(action: {
                    locationManager.zoomOut()
                }, label: {
                    Text("Zoom Out")
                })
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .clipShape(Circle())
            }

            Button(action: {
                self.showDirections.toggle()
            }, label: {
                Text("Show Directions")
            })
            .disabled(directions.isEmpty)
            .padding()
        }.sheet(isPresented: $showDirections, content: {
            VStack(spacing: 0) {
                Text("Directions")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Divider().background(Color.blue)

                List(directions, id: \.self) { direction in
                    Text(direction).padding()
                }
            }
        })
    }
}

struct MapView: UIViewRepresentable {
    @Binding var directions: [String]
    @EnvironmentObject var locationManager: LocationManager

    func makeCoordinator() -> MapViewCoordinator {
        MapViewCoordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.showsUserLocation = true
        mapView.delegate = context.coordinator

        // Initialize the map view with the user's last known location
        let region = MKCoordinateRegion(
            center: locationManager.lastLocation?.coordinate ?? CLLocationCoordinate2D(latitude: 40.71, longitude: -74),
            span: locationManager.regionSpan)
        mapView.setRegion(region, animated: true)

        setupDirections(on: mapView)
        return mapView
    }

    func updateUIView(_ uiView: MKMapView, context: Context) {
        if let location = locationManager.lastLocation?.coordinate {
            let region = MKCoordinateRegion(center: location, span: locationManager.regionSpan)
            uiView.setRegion(region, animated: true)
        }
    }

    private func setupDirections(on mapView: MKMapView) {
        let p1 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 40.71, longitude: -74)) // NYC
        let p2 = MKPlacemark(coordinate: CLLocationCoordinate2D(latitude: 42.36, longitude: -71.05)) // Boston
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: p1)
        request.destination = MKMapItem(placemark: p2)
        request.transportType = .automobile

        let directions = MKDirections(request: request)
        directions.calculate { response, error in
            guard let route = response?.routes.first else { return }
            mapView.addAnnotations([p1, p2])
            mapView.addOverlay(route.polyline)
            mapView.setVisibleMapRect(route.polyline.boundingMapRect, edgePadding: UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20), animated: true)
            self.directions = route.steps.map { $0.instructions }.filter { !$0.isEmpty }
        }
    }

    class MapViewCoordinator: NSObject, MKMapViewDelegate {
        var parent: MapView

        init(_ parent: MapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = .blue
            renderer.lineWidth = 5
            return renderer
        }
    }
}

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var lastLocation: CLLocation?
    @Published var regionSpan = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest

        #if targetEnvironment(simulator)
        // Using a fixed location (New York) when on the iOS Simulator
        lastLocation = CLLocation(latitude: 40.7128, longitude: -74.0060)
        #else
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        #endif
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastLocation = locations.last
    }

    func zoomIn() {
        regionSpan = MKCoordinateSpan(latitudeDelta: regionSpan.latitudeDelta * 0.5, longitudeDelta: regionSpan.longitudeDelta * 0.5)
    }

    func zoomOut() {
        regionSpan = MKCoordinateSpan(latitudeDelta: regionSpan.latitudeDelta * 2, longitudeDelta: regionSpan.longitudeDelta * 2)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        GPSContentView().environmentObject(LocationManager())
    }
}
