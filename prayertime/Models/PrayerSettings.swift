import SwiftUI
import CoreLocation
import Adhan

class PrayerSettings: ObservableObject {
    private let defaults = UserDefaults(suiteName: "group.bd.com.islamicguidence.prayertime")
    
    @AppStorage("calculationMethod", store: UserDefaults(suiteName: "group.bd.com.islamicguidence.prayertime"))
    var calculationMethod: String = "muslimWorldLeague"
    
    @AppStorage("city", store: UserDefaults(suiteName: "group.bd.com.islamicguidence.prayertime"))
    var city: String = ""
    
    @AppStorage("useLocation", store: UserDefaults(suiteName: "group.bd.com.islamicguidence.prayertime"))
    var useLocation: Bool = true
    
    var coordinates: CLLocationCoordinate2D? {
        didSet {
            if let coords = coordinates {
                defaults?.set([
                    "latitude": coords.latitude,
                    "longitude": coords.longitude
                ], forKey: "LastKnownLocation")
            }
        }
    }
} 