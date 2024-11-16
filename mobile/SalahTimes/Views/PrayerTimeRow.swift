import SwiftUI

struct PrayerTimeRow: View {
    let prayer: PrayerTime
    
    var body: some View {
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