import Adhan

enum CalculationMethod: String, CaseIterable {
    case muslimWorldLeague = "Muslim World League"
    case northAmerica = "North America"
    case egyptian = "Egyptian"
    case karachi = "Karachi"
    case dubai = "Dubai"
    case kuwait = "Kuwait"
    case qatar = "Qatar"
    case singapore = "Singapore"
    case tehran = "Tehran"
    case turkey = "Turkey"
    case other = "Other"
    case moonsightingCommittee = "Moonsighting Committee"
    case ummAlQura = "Umm Al-Qura"
    
    var params: CalculationParameters {
        switch self {
        case .muslimWorldLeague: return CalculationMethod.muslimWorldLeague.params
        case .northAmerica: return CalculationMethod.northAmerica.params
        case .egyptian: return CalculationMethod.egyptian.params
        case .karachi: return CalculationMethod.karachi.params
        case .dubai: return CalculationMethod.dubai.params
        case .kuwait: return CalculationMethod.kuwait.params
        case .qatar: return CalculationMethod.qatar.params
        case .singapore: return CalculationMethod.singapore.params
        case .tehran: return CalculationMethod.tehran.params
        case .turkey: return CalculationMethod.turkey.params
        case .other: return CalculationMethod.other.params
        case .moonsightingCommittee: return CalculationMethod.moonsightingCommittee.params
        case .ummAlQura: return CalculationMethod.ummAlQura.params
        }
    }
} 