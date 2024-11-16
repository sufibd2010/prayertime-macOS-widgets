import WidgetKit
import SwiftUI
import CoreLocation
import Adhan

struct SalahTimesProvider: TimelineProvider {
    let defaults = UserDefaults(suiteName: "group.com.yourapp.prayertime")
    
    func placeholder(in context: Context) -> SalahTimesEntry {
        let currentDate = Date()
        let samplePrayerTimes = [
            PrayerTime(name: "Fajr", time: currentDate),
            PrayerTime(name: "Dhuhr", time: currentDate.addingTimeInterval(21600)),
            PrayerTime(name: "Asr", time: currentDate.addingTimeInterval(32400)),
            PrayerTime(name: "Maghrib", time: currentDate.addingTimeInterval(43200)),
            PrayerTime(name: "Isha", time: currentDate.addingTimeInterval(54000))
        ]
        return SalahTimesEntry(date: currentDate, prayerTimes: samplePrayerTimes)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SalahTimesEntry) -> ()) {
        let entry = placeholder(in: context)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<SalahTimesEntry>) -> ()) {
        let currentDate = Date()
        let prayerTimes = calculatePrayerTimes(for: currentDate)
        
        let entry = SalahTimesEntry(
            date: currentDate,
            prayerTimes: prayerTimes
        )
        
        let nextUpdateDate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdateDate))
        completion(timeline)
    }
    
    private func calculatePrayerTimes(for date: Date) -> [PrayerTime] {
        var coordinates = CLLocationCoordinate2D(latitude: 23.777176, longitude: 90.399452)
        if let savedLocation = defaults?.dictionary(forKey: "LastKnownLocation") {
            if let latitude = savedLocation["latitude"] as? Double,
               let longitude = savedLocation["longitude"] as? Double {
                coordinates = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            }
        }
        
        let cal = Calendar(identifier: .gregorian)
        let components = cal.dateComponents([.year, .month, .day], from: date)
        
        let calculationMethod = defaults?.string(forKey: "calculationMethod") ?? "muslimWorldLeague"
        let params = CalculationMethod(rawValue: calculationMethod)?.params ?? CalculationMethod.muslimWorldLeague.params
        
        let adhanCoordinates = Coordinates(latitude: coordinates.latitude, longitude: coordinates.longitude)
        let dateComponents = DateComponents(calendar: cal, year: components.year, month: components.month, day: components.day)
        
        if let prayers = PrayerTimes(coordinates: adhanCoordinates, date: dateComponents, calculationParameters: params) {
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