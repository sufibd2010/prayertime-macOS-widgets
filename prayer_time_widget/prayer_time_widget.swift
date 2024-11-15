// PrayerTimesWidget.swift
import WidgetKit
import SwiftUI
import CoreLocation
import Adhan
import UserNotifications

struct PrayerTime: Identifiable {
    let id = UUID()
    let name: String
    let time: Date
    var isNextPrayer: Bool = false
}

class PrayerSettings: ObservableObject {
    @AppStorage("calculationMethod") var calculationMethod: CalculationMethod = .muslimWorldLeague
    @AppStorage("city") var city: String = ""
    @AppStorage("useLocation") var useLocation: Bool = true
    
    var coordinates: CLLocationCoordinate2D? {
        didSet {
            if let coords = coordinates {
                UserDefaults.standard.set([
                    "latitude": coords.latitude,
                    "longitude": coords.longitude
                ], forKey: "LastKnownLocation")
            }
        }
    }
}



// Main Widget View
struct PrayerTimesWidgetView: View {
    @State private var prayerTimes: [PrayerTime]
    @StateObject private var settings = PrayerSettings()
    @State private var isSettingsPresented = false
    private let locationManager = LocationManager.shared
    
    init(prayerTimes: [PrayerTime]) {
        _prayerTimes = State(initialValue: prayerTimes)
    }
    
    var body: some View {
        VStack(spacing: 12) {
            headerView
            prayerTimesListView
            settingsButton
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var headerView: some View {
        HStack {
            Text(settings.city.isEmpty ? "Prayer Times" : settings.city)
                .font(.headline)
            Spacer()
            Text(Date(), style: .date)
                .font(.subheadline)
        }
    }
    
    private var prayerTimesListView: some View {
        ForEach(prayerTimes) { prayer in
            HStack {
                Image(systemName: getPrayerIcon(for: prayer.name))
                    .foregroundColor(.accentColor)
                Text(prayer.name)
                    .font(.system(.body, design: .rounded))
                Spacer()
                Text(formatTime(prayer.time))
                    .font(.system(.body, design: .monospaced))
                if prayer.isNextPrayer {
                    Image(systemName: "bell.fill")
                        .foregroundColor(.yellow)
                }
            }
            .padding(.vertical, 4)
            .accessibilityLabel("\(prayer.name) prayer at \(formatTime(prayer.time))")
            .accessibilityHint(prayer.isNextPrayer ? "Next prayer time" : "")
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            if let url = URL(string: "prayertime://settings") {
                NSWorkspace.shared.open(url)
            }
        }) {
            Label("Settings", systemImage: "gear")
        }
    }
    
    // MARK: - Helper Functions
    private func setupLocationServices() {
        locationManager.onLocationUpdate = { location in
            settings.coordinates = location.coordinate
            
            // Reverse geocode to get city name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let city = placemarks?.first?.locality {
                    settings.city = city
                }
            }
            
            updatePrayerTimes()
        }
        
        locationManager.onLocationError = { error in
            print("Location error: \(error.localizedDescription)")
            // Fall back to default location or saved location
            if let savedCoordinates = UserDefaults.standard.object(forKey: "LastKnownLocation") as? [String: Double] {
                settings.coordinates = CLLocationCoordinate2D(
                    latitude: savedCoordinates["latitude"] ?? 0,
                    longitude: savedCoordinates["longitude"] ?? 0
                )
                updatePrayerTimes()
            }
        }
        
        if settings.useLocation {
            locationManager.requestLocation()
        }
    }
    
    private func updatePrayerTimes() {
        guard let coordinates = settings.coordinates else { return }
        
        let cal = Calendar(identifier: .gregorian)
        let date = cal.dateComponents([.year, .month, .day], from: Date())
        
        // Configure calculation parameters based on selected method
        var params: CalculationParameters
        switch settings.calculationMethod {
        case .muslimWorldLeague:
            params = CalculationMethod.muslimWorldLeague.params
        case .northAmerica:
            params = CalculationMethod.northAmerica.params
        case .egyptian:
            params = CalculationMethod.egyptian.params
        case .karachi:
            params = CalculationMethod.karachi.params
        case .dubai:
            params = CalculationMethod.dubai.params
        case .kuwait:
            params = CalculationMethod.kuwait.params
        case .qatar:
            params = CalculationMethod.qatar.params
        case .singapore:
            params = CalculationMethod.singapore.params
        case .tehran:
            params = CalculationMethod.tehran.params
        case .turkey:
            params = CalculationMethod.turkey.params
        case .other:
            params = CalculationMethod.other.params
        case .moonsightingCommittee:
            params = CalculationMethod.moonsightingCommittee.params
        case .ummAlQura:
            params = CalculationMethod.ummAlQura.params
        }
        
        let adhanCoordinates = Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        if let prayers = PrayerTimes(coordinates: adhanCoordinates, date: date, calculationParameters: params) {
            let now = Date()
            
            var times: [PrayerTime] = [
                PrayerTime(name: "Fajr", time: prayers.fajr),
                PrayerTime(name: "Dhuhr", time: prayers.dhuhr),
                PrayerTime(name: "Asr", time: prayers.asr),
                PrayerTime(name: "Maghrib", time: prayers.maghrib),
                PrayerTime(name: "Isha", time: prayers.isha)
            ]
            
            // Find next prayer
            if let nextPrayer = times.first(where: { $0.time > now }) {
                let index = times.firstIndex(where: { $0.id == nextPrayer.id })!
                times[index].isNextPrayer = true
            }
            
            prayerTimes = times
        }
    }
    
    private func getPrayerIcon(for prayer: String) -> String {
        switch prayer {
        case "Fajr": return "sunrise.fill"
        case "Dhuhr": return "sun.max.fill"
        case "Asr": return "sun.min.fill"
        case "Maghrib": return "sunset.fill"
        case "Isha": return "moon.stars.fill"
        default: return "clock.fill"
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    static func calculatePrayerTimes(for date: Date) -> [PrayerTime] {
        // Default to Mecca coordinates if no saved location
        let coordinates: CLLocationCoordinate2D
        if let savedLocation = UserDefaults.standard.object(forKey: "LastKnownLocation") as? [String: Double],
           let latitude = savedLocation["latitude"],
           let longitude = savedLocation["longitude"] {
            coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        } else {
            // Dhaka coordinates as default
            coordinates = CLLocationCoordinate2D(latitude: 23.777176, longitude: 90.399452)
        }
        
        // Rest of the function remains the same
        let methodRawValue = UserDefaults.standard.string(forKey: "calculationMethod") ?? "muslimWorldLeague"
        let calculationMethod = CalculationMethod(rawValue: methodRawValue) ?? .muslimWorldLeague
        
        let cal = Calendar(identifier: .gregorian)
        let dateComponents = cal.dateComponents([.year, .month, .day], from: date)
        
        // Use the selected calculation method
        let params = calculationMethod.params
        
        let adhanCoordinates = Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        if let prayers = PrayerTimes(coordinates: adhanCoordinates, date: dateComponents, calculationParameters: params) {
            let now = Date()
            var times = [
                PrayerTime(name: "Fajr", time: prayers.fajr),
                PrayerTime(name: "Dhuhr", time: prayers.dhuhr),
                PrayerTime(name: "Asr", time: prayers.asr),
                PrayerTime(name: "Maghrib", time: prayers.maghrib),
                PrayerTime(name: "Isha", time: prayers.isha)
            ]
            
            // Mark next prayer
            if let nextPrayer = times.first(where: { $0.time > now }) {
                let index = times.firstIndex(where: { $0.id == nextPrayer.id })!
                times[index].isNextPrayer = true
            }
            
            return times
        }
        return []
    }
}

// Settings View
struct SettingsView: View {
    @ObservedObject var settings: PrayerSettings
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("Location") {
                Toggle("Use Current Location", isOn: $settings.useLocation)
                if !settings.useLocation {
                    TextField("City", text: $settings.city)
                }
            }
            
            Section("Calculation Method") {
                Picker("Method", selection: $settings.calculationMethod) {
                    ForEach(CalculationMethod.allCases, id: \.self) { method in
                        Text(method.rawValue).tag(method)
                    }
                }
            }
        }
        .padding()
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") {
                    dismiss()
                }
            }
        }
    }
}

// Location Manager Extension
class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private let locationManager = CLLocationManager()
    var onLocationUpdate: ((CLLocation) -> Void)?
    var onLocationError: ((Error) -> Void)?
    
    override init() {
        super.init()
        locationManager.delegate = self
    }
    
    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationError?(error)
    }
}

// Notification Manager
class NotificationManager {
    static let shared = NotificationManager()
    
    func scheduleNotification(for prayerTime: PrayerTime) {
        let content = UNMutableNotificationContent()
        content.title = "Prayer Time"
        content.body = "\(prayerTime.name) time has arrived"
        content.sound = UNNotificationSound.default
        
        let components = Calendar.current.dateComponents([.hour, .minute], from: prayerTime.time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(identifier: prayerTime.id.uuidString,
                                          content: content,
                                          trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
}

// Widget Configuration
struct PrayerTimesWidget: Widget {
    private let kind = "PrayerTimesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PrayerTimesProvider()) { entry in
            PrayerTimesWidgetView(prayerTimes: entry.prayerTimes)
                .containerBackground(.background, for: .widget)
        }
        .configurationDisplayName("Prayer Times")
        .description("Display daily prayer times")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// Widget Provider
struct PrayerTimesProvider: TimelineProvider {
    typealias Entry = PrayerTimesEntry
    
    func placeholder(in context: Context) -> Entry {
        return PrayerTimesEntry.placeholder()
    }
    
    func getSnapshot(in context: Context, completion: @escaping (Entry) -> Void) {
        let entry = context.isPreview ? 
            PrayerTimesEntry.placeholder() : 
            PrayerTimesEntry(date: Date(), prayerTimes: PrayerTimesWidgetView.calculatePrayerTimes(for: Date()))
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> Void) {
        var entries: [PrayerTimesEntry] = []
        let currentDate = Date()
        let calendar = Calendar.current
        
        // Create entries for next 24 hours
        for hourOffset in 0..<24 {
            let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let times = PrayerTimesWidgetView.calculatePrayerTimes(for: entryDate)
            let entry = PrayerTimesEntry(date: entryDate, prayerTimes: times)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct PrayerTimesEntry: TimelineEntry {
    let date: Date
    let prayerTimes: [PrayerTime]
    
    static func placeholder() -> PrayerTimesEntry {
        let times = [
            PrayerTime(name: "Fajr", time: Date()),
            PrayerTime(name: "Dhuhr", time: Date()),
            PrayerTime(name: "Asr", time: Date()),
            PrayerTime(name: "Maghrib", time: Date()),
            PrayerTime(name: "Isha", time: Date())
        ]
        return PrayerTimesEntry(date: Date(), prayerTimes: times)
    }
}
