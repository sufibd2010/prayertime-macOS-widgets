// PrayerTimesWidget.swift
import WidgetKit
import SwiftUI
import CoreLocation
import Adhan
import UserNotifications

struct PrayerTime: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let time: Date
    var isNextPrayer: Bool = false
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: PrayerTime, rhs: PrayerTime) -> Bool {
        lhs.id == rhs.id
    }
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
        VStack(spacing: 8) {
            headerView
            prayerTimesListView
            settingsButton
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var headerView: some View {
        HStack {
            Text(settings.city.isEmpty ? "Prayer Times" : settings.city)
                .font(.caption)
                .fontWeight(.medium)
            Spacer()
            Text(Date(), style: .date)
                .font(.caption2)
        }
    }
    
    private var prayerTimesListView: some View {
        VStack(spacing: 4) {
            ForEach(prayerTimes) { prayer in
                HStack {
                    Image(systemName: getPrayerIcon(for: prayer.name))
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    Text(prayer.name)
                        .font(.system(.caption, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                    Text(formatTime(prayer.time))
                        .font(.system(.caption, design: .monospaced))
                    if prayer.isNextPrayer {
                        Image(systemName: "bell.fill")
                            .foregroundColor(.yellow)
                            .font(.system(size: 10))
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
            }
        }
    }
    
    private var settingsButton: some View {
        Button(action: {
            if let url = URL(string: "prayertime://settings") {
                NSWorkspace.shared.open(url)
            }
        }) {
            Label("Settings", systemImage: "gear")
                .font(.caption2)
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }
    
    // MARK: - Helper Functions
    private func setupLocationServices() {
        LocationManager.shared.onLocationUpdate = { location in
            settings.coordinates = location.coordinate
            
            // Reverse geocode to get city name
            let geocoder = CLGeocoder()
            geocoder.reverseGeocodeLocation(location) { placemarks, error in
                if let error = error {
                    print("Reverse geocoding error: \(error.localizedDescription)")
                    return
                }
                
                if let city = placemarks?.first?.locality {
                    DispatchQueue.main.async {
                        settings.city = city
                    }
                }
            }
            
            updatePrayerTimes()
        }
        
        LocationManager.shared.onLocationError = { error in
            print("Location error: \(error.localizedDescription)")
            // Fall back to last known location
            if let savedLocation = UserDefaults.standard.dictionary(forKey: "LastKnownLocation") {
                if let latitude = savedLocation["latitude"] as? Double,
                   let longitude = savedLocation["longitude"] as? Double {
                    settings.coordinates = CLLocationCoordinate2D(
                        latitude: latitude,
                        longitude: longitude
                    )
                    updatePrayerTimes()
                }
            }
        }
        
        if settings.useLocation {
            LocationManager.shared.requestLocation()
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
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
        locationManager.distanceFilter = 1000 // Update only when moved 1km
    }
    
    func requestLocation() {
        let status = locationManager.authorizationStatus
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        default:
            onLocationError?(NSError(domain: "LocationManager", code: 1, 
                userInfo: [NSLocalizedDescriptionKey: "Location permission denied"]))
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        // Filter out invalid or inaccurate locations
        if location.horizontalAccuracy < 0 || location.horizontalAccuracy > 10000 {
            return
        }
        
        onLocationUpdate?(location)
        stopUpdatingLocation() // Stop after getting a good location
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationError?(error)
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            onLocationError?(NSError(domain: "LocationManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Location access denied"]))
        default:
            break
        }
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
        }
        .configurationDisplayName("Prayer Times")
        .description("Display daily prayer times")
        .supportedFamilies([.systemSmall, .systemMedium])
        .onBackgroundURLSessionEvents { identifier, completion in
            print("Widget background session event: \(identifier)")
            completion()
        }
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
        print("Getting timeline")
        let currentDate = Date()
        let prayerTimes = calculatePrayerTimes(for: currentDate)
        print("Calculated prayer times: \(prayerTimes.count)")
        
        let entry = PrayerTimesEntry(
            date: currentDate,
            prayerTimes: prayerTimes
        )
        
        // Update timeline every hour
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func calculatePrayerTimes(for date: Date) -> [PrayerTime] {
        let defaults = UserDefaults(suiteName: "group.bd.com.islamicguidence.prayertime")
        print("Using UserDefaults suite: \(defaults?.description ?? "standard")")
        
        // Get coordinates (using Dhaka as default)
        var coordinates = CLLocationCoordinate2D(latitude: 23.777176, longitude: 90.399452)
        if let savedLocation = defaults?.dictionary(forKey: "LastKnownLocation") {
            if let latitude = savedLocation["latitude"] as? Double,
               let longitude = savedLocation["longitude"] as? Double {
                coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
        
        let cal = Calendar(identifier: .gregorian)
        let dateComponents = cal.dateComponents([.year, .month, .day], from: date)
        
        // Get calculation method
        let methodKey = defaults?.string(forKey: "calculationMethod") ?? "muslimWorldLeague"
        let params = CalculationMethod(rawValue: methodKey)?.params ?? 
                    CalculationMethod.muslimWorldLeague.params
        
        let adhanCoordinates = Coordinates(latitude: coordinates.latitude, 
                                         longitude: coordinates.longitude)
        
        if let prayers = PrayerTimes(coordinates: adhanCoordinates, 
                                   date: dateComponents, 
                                   calculationParameters: params) {
            var times = [
                PrayerTime(name: "Fajr", time: prayers.fajr),
                PrayerTime(name: "Dhuhr", time: prayers.dhuhr),
                PrayerTime(name: "Asr", time: prayers.asr),
                PrayerTime(name: "Maghrib", time: prayers.maghrib),
                PrayerTime(name: "Isha", time: prayers.isha)
            ]
            
            if let nextPrayer = findNextPrayer(times) {
                times[nextPrayer].isNextPrayer = true
            }
            
            return times
        }
        return []
    }
        private func findNextPrayer(_ prayers: [PrayerTime]) -> Int? {
        let now = Date()
        for (index, prayer) in prayers.enumerated() {
            if prayer.time > now {
                return index
            }
        }
        return nil
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


