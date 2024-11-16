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
        case .muslimWorldLeague:
            return Adhan.CalculationMethod.muslimWorldLeague.params
        case .northAmerica:
            return Adhan.CalculationMethod.northAmerica.params
        case .egyptian:
            return Adhan.CalculationMethod.egyptian.params
        case .karachi:
            return Adhan.CalculationMethod.karachi.params
        case .dubai:
            return Adhan.CalculationMethod.dubai.params
        case .kuwait:
            return Adhan.CalculationMethod.kuwait.params
        case .qatar:
            return Adhan.CalculationMethod.qatar.params
        case .singapore:
            return Adhan.CalculationMethod.singapore.params
        case .tehran:
            return Adhan.CalculationMethod.tehran.params
        case .turkey:
            return Adhan.CalculationMethod.turkey.params
        case .other:
            return Adhan.CalculationMethod.other.params
        case .moonsightingCommittee:
            return Adhan.CalculationMethod.moonsightingCommittee.params
        case .ummAlQura:
            return Adhan.CalculationMethod.ummAlQura.params
        }
    }
} 