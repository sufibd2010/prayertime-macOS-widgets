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