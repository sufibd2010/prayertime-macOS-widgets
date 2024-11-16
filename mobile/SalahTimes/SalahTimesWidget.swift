import SwiftUI
import WidgetKit

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