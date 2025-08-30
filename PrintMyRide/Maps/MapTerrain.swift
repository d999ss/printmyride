import MapKit

enum MapTerrain: String, CaseIterable, Identifiable {
    case muted, standard, hybrid
    var id: String { rawValue }
    var mapType: MKMapType {
        switch self {
        case .muted:    return .mutedStandard
        case .standard: return .standard
        case .hybrid:   return .hybrid
        }
    }
    var label: String {
        switch self {
        case .muted: return "Muted"
        case .standard: return "Street"
        case .hybrid: return "Hybrid"
        }
    }
}