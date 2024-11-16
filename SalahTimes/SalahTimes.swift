//
//  SalahTimes.swift
//  SalahTimes
//
//  Created by Md. Abu Sufian Sufi on 11/16/24.
//

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

// Location Manager
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        onLocationUpdate?(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        onLocationError?(error)
    }
}

struct SalahTimesWidget: Widget {
    private let kind = "SalahTimesWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: SalahTimesProvider()) { entry in
            SalahTimesWidgetView(prayerTimes: entry.prayerTimes)
        }
        .configurationDisplayName("Salah Times")
        .description("Display daily prayer times")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct SalahTimesWidgetView: View {
    let prayerTimes: [PrayerTime]
    
    var body: some View {
        VStack(spacing: 8) {
            headerView
            prayerTimesListView
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var headerView: some View {
        HStack {
            Text("Prayer Times")
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
}

struct SalahTimesProvider: TimelineProvider {
    func placeholder(in context: Context) -> SalahTimesEntry {
        // Create sample prayer times for placeholder
        let currentDate = Date()
        let samplePrayerTimes = [
            PrayerTime(name: "Fajr", time: currentDate.addingTimeInterval(0)),
            PrayerTime(name: "Dhuhr", time: currentDate.addingTimeInterval(21600)),
            PrayerTime(name: "Asr", time: currentDate.addingTimeInterval(32400)),
            PrayerTime(name: "Maghrib", time: currentDate.addingTimeInterval(43200)),
            PrayerTime(name: "Isha", time: currentDate.addingTimeInterval(54000))
        ]
        return SalahTimesEntry(date: currentDate, prayerTimes: samplePrayerTimes)
    }

    func getSnapshot(in context: Context, completion: @escaping (SalahTimesEntry) -> ()) {
        print("Getting snapshot...")
        let prayerTimes = calculatePrayerTimes(for: Date())
        print("Prayer times calculated: \(prayerTimes.count) times")
        let entry = SalahTimesEntry(date: Date(), prayerTimes: prayerTimes)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<SalahTimesEntry>) -> ()) {
        var entries: [SalahTimesEntry] = []
        let currentDate = Date()
        let calendar = Calendar(identifier: .gregorian)
        
        // Create timeline entries for the next 24 hours
        for hourOffset in 0 ..< 24 {
            let entryDate = calendar.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SalahTimesEntry(date: entryDate, prayerTimes: calculatePrayerTimes(for: entryDate))
            entries.append(entry)
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
    
    private func calculatePrayerTimes(for date: Date) -> [PrayerTime] {
        // Try to get saved location from UserDefaults
        var coordinates = CLLocationCoordinate2D(latitude: 23.777176, longitude: 90.399452) // Default coordinates
        if let savedLocation = UserDefaults.standard.dictionary(forKey: "LastKnownLocation") {
            if let latitude = savedLocation["latitude"] as? Double,
               let longitude = savedLocation["longitude"] as? Double {
                coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
        
        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: date)
        let year = components.year ?? 0
        let month = components.month ?? 0
        let day = components.day ?? 0
        
        // Get calculation method from settings
        let calculationMethod = UserDefaults.standard.string(forKey: "calculationMethod") ?? "muslimWorldLeague"
        let params = CalculationMethod(rawValue: calculationMethod)?.params ?? CalculationMethod.muslimWorldLeague.params
        
        let adhanCoordinates = Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let dateComponents = DateComponents(calendar: cal, year: year, month: month, day: day)
        
        if let prayers = PrayerTimes(coordinates: adhanCoordinates, date: dateComponents, calculationParameters: params) {
            var times = [
                PrayerTime(name: "Fajr", time: prayers.fajr),
                PrayerTime(name: "Dhuhr", time: prayers.dhuhr),
                PrayerTime(name: "Asr", time: prayers.asr),
                PrayerTime(name: "Maghrib", time: prayers.maghrib),
                PrayerTime(name: "Isha", time: prayers.isha)
            ]
            
            // Mark next prayer
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

struct SalahTimesEntry: TimelineEntry {
    let date: Date
    let prayerTimes: [PrayerTime]
}




