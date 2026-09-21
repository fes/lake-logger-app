import Foundation

/// Display unit preference for the whole app (and widget). Persisted via
/// `AppSettingsStore`.
enum UnitSystem: String, CaseIterable, Codable, Identifiable {
    case metric
    case imperial

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .metric: return "Metric"
        case .imperial: return "Imperial"
        }
    }
}
