import SwiftUI





struct Destination_Object: Codable {
    let location: String
    var objects: [String]
}

struct DashboardScreen: View {
    @State private var destinations: [Destination_Object] = []
    @State private var selectedLocation: String = ""
    
    init() {
        setupDestinations()
    }
    
    var body: some View {
        NavigationView {
            List(destinations, id: \.location) { destination in
                NavigationLink(destination: DestinationDetailView(destination: destination)) {
                    HStack {
                        Text(destination.location)
                        Spacer()
                        Text("\(destination.objects.count) items")
                            .foregroundColor(.gray)
                    }
                }
            }
            .navigationBarTitle("Select Location")
        }
        .onAppear {
            loadDestinations()
        }
    }
    
    private func setupDestinations() {
        // Dummy destinations setup
        let dummyDestinations = [
            Destination_Object(location: "Paris", objects: ["Eiffel Tower", "Louvre Museum"]),
            Destination_Object(location: "New York", objects: ["Statue of Liberty", "Central Park", "Central Park", "Central Park"])
        ]
        
        // Encode and store destinations
        if let encodedData = try? JSONEncoder().encode(dummyDestinations) {
            UserDefaults.standard.set(encodedData, forKey: "dashboard")
        }
    }
    
    private func loadDestinations() {
        if let data = UserDefaults.standard.data(forKey: "dashboard"),
           let decodedDestinations = try? JSONDecoder().decode([Destination_Object].self, from: data) {
            destinations = decodedDestinations
        }
    }
}

struct DestinationDetailView: View {
    var destination: Destination_Object
    
    var body: some View {
        List {
            // Custom header
            HStack {
                Text("Object")
                    .bold()
                    .frame(width: 150, alignment: .leading)
                Spacer()
                Text("Count")
                    .bold()
                    .frame(width: 50, alignment: .trailing)
            }
            
            // List of items
            ForEach(groupedObjects, id: \.key) { (object, count) in
                HStack {
                    Text(object)
                        .frame(width: 150, alignment: .leading)
                    Spacer()
                    Text("\(count)")
                        .frame(width: 50, alignment: .trailing)
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationBarTitle(destination.location)
    }
    
    // Helper property to group and count objects
    private var groupedObjects: [(key: String, value: Int)] {
        let groupedItems = Dictionary(destination.objects.map { ($0, 1) }, uniquingKeysWith: +)
        return groupedItems.map { ($0.key, $0.value) }.sorted { $0.key < $1.key }
    }
}

struct DashboardScreen_Previews: PreviewProvider {
    static var previews: some View {
        DashboardScreen()
    }
}
