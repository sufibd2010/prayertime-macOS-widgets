import SwiftUI
import CoreLocation

struct SettingsView: View {
    @ObservedObject var settings: PrayerSettings
    @StateObject private var locationManager = LocationManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Location Settings")) {
                Toggle("Use Current Location", isOn: $settings.useLocation)
                
                if !settings.useLocation {
                    TextField("City", text: $settings.city)
                }
            }
            
            Section(header: Text("Calculation Method")) {
                Picker("Calculation Method", selection: $settings.calculationMethod) {
                    Text("Muslim World League").tag("muslimWorldLeague")
                    Text("Egyptian").tag("egyptian")
                    Text("Karachi").tag("karachi")
                    Text("UmmAlQura").tag("ummAlQura")
                    Text("Dubai").tag("dubai")
                    Text("Qatar").tag("qatar")
                    Text("Kuwait").tag("kuwait")
                    Text("Singapore").tag("singapore")
                }
            }
        }
        .onAppear {
            if settings.useLocation {
                locationManager.requestLocation()
                locationManager.onLocationUpdate = { location in
                    settings.coordinates = location.coordinate
                }
            }
        }
    }
} 
