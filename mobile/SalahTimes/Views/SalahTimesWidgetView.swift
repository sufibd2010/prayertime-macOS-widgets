import SwiftUI

struct SalahTimesWidgetView: View {
    let prayerTimes: [PrayerTime]
    
    var body: some View {
        VStack(spacing: 4) {
            headerView
            prayerTimesListView
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
    
    private var headerView: some View {
        HStack {
            Spacer()
            Image(systemName: "gearshape.fill")
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
    
    private var prayerTimesListView: some View {
        VStack(spacing: 4) {
            ForEach(prayerTimes) { prayer in
                PrayerTimeRow(prayer: prayer)
            }
        }
    }
} 