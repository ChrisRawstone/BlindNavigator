import SwiftUI



// Model for destination object which conforms to Codable for easy encoding and decoding
struct Destination_Object: Codable {
    let location: String
    var objects: [String]
}


// Main view for the dashboard screen
struct DashboardScreen: View {
    // State variables to hold the list of destinations and the selected location
    @State private var destinations: [Destination_Object] = []
    @State private var selectedLocation: String = ""
    

    var body: some View {
        // Navigation view to enable navigation between views
        NavigationView {
            List(destinations, id: \.location) { destination in
                // Navigation link to navigate to detail view of the selected destination
                NavigationLink(destination: DestinationDetailView(destination: destination)) {
                    HStack {
                        // Display the location name
                        Text(destination.location)
                        Spacer()
                        // Display the number of objects in the location
                        Text("\(destination.objects.count) items")
                            .foregroundColor(.gray)
                    }
                }
            }
            // Set the title of the navigation bar
            .navigationBarTitle("Select Location")
        }
        // Load destinations when the view appears
        .onAppear {
            loadDestinations()
        }
    }
    
    // Function to load destinations from UserDefaults
    private func loadDestinations() {
        // Retrieve data from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "dashboard"),
           let decodedDestinations = try? JSONDecoder().decode([Destination_Object].self, from: data) {
            // Decode data and assign it to the destinations state variable
            destinations = decodedDestinations
        }
    }
}

// Detail view for displaying objects in a selected destination
struct DestinationDetailView: View {
    var destination: Destination_Object
    
    var body: some View {
        // List to display grouped and counted objects
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
            
            // Iterate over grouped objects and display them
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
        // Set the title of the navigation bar to the location name
        .navigationBarTitle(destination.location)
    }
    
    // Helper property to group and count objects
    private var groupedObjects: [(key: String, value: Int)] {
        // Group objects by their name and count occurrences
        let groupedItems = Dictionary(destination.objects.map { ($0, 1) }, uniquingKeysWith: +)
        // Convert dictionary to a sorted array of tuples
        return groupedItems.map { ($0.key, $0.value) }.sorted { $0.key < $1.key }
    }
}
// Preview provider for the dashboard screen
struct DashboardScreen_Previews: PreviewProvider {
    static var previews: some View {
        DashboardScreen()
    }
}
