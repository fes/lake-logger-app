import Foundation

/// Persists app-wide display preferences (unit system, which history graphs
/// are shown, history chart duration) in the shared App Group container --
/// same storage convention as `DeviceSettingsStore` -- so the widget can
/// read them too in the future without any migration.
enum AppSettingsStore {
    private static let unitSystemKey = "unitSystemPreference"
    private static let selectedGraphsKey = "selectedGraphSeries"
    private static let historyDaysKey = "historyDurationDays"

    /// Duration options offered in Settings. `.setHistoryDays` and the
    /// history fetch itself both accept any `Int`, but the UI only offers
    /// these so the API isn't asked for an unreasonable range.
    static let availableHistoryDays: [Int] = [1, 3, 7, 14, 30]
    static let defaultHistoryDays = 7

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: SharedReadingCache.appGroupId)
    }

    static func loadUnitSystem() -> UnitSystem {
        guard let raw = defaults?.string(forKey: unitSystemKey),
              let value = UnitSystem(rawValue: raw) else {
            return .metric
        }
        return value
    }

    static func saveUnitSystem(_ unitSystem: UnitSystem) {
        defaults?.set(unitSystem.rawValue, forKey: unitSystemKey)
    }

    static func loadSelectedGraphs() -> Set<GraphSeries> {
        guard let rawValues = defaults?.array(forKey: selectedGraphsKey) as? [String] else {
            return GraphSeries.defaultSelection
        }
        let series = rawValues.compactMap(GraphSeries.init(rawValue:))
        // Guard against an empty persisted selection (e.g. from a decoding
        // mismatch after an app update) leaving the user with no charts at
        // all and no obvious way to tell why.
        return series.isEmpty ? GraphSeries.defaultSelection : Set(series)
    }

    static func saveSelectedGraphs(_ series: Set<GraphSeries>) {
        defaults?.set(series.map(\.rawValue), forKey: selectedGraphsKey)
    }

    static func loadHistoryDays() -> Int {
        let stored = defaults?.integer(forKey: historyDaysKey) ?? 0
        // `UserDefaults.integer(forKey:)` returns 0 for a missing key, which
        // is never a valid duration, so treat it as "not set yet".
        return stored > 0 ? stored : defaultHistoryDays
    }

    static func saveHistoryDays(_ days: Int) {
        defaults?.set(days, forKey: historyDaysKey)
    }
}
