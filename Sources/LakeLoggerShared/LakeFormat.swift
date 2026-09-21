import Foundation

enum LakeFormat {
    /// Water level, unit-converted per `unitSystem` (defaults to metric so
    /// existing callers, e.g. the widget, are unaffected until they opt in).
    static func meters(_ value: Double?, unitSystem: UnitSystem = .metric, fractionDigits: Int? = nil) -> String {
        guard let value else { return "—" }
        let converted = GraphSeries.waterLevel.displayValue(value, unitSystem: unitSystem)
        let digits = fractionDigits ?? (unitSystem == .imperial ? 2 : 3)
        return String(format: "%.\(digits)f \(GraphSeries.waterLevel.unitLabel(unitSystem: unitSystem))", converted)
    }

    /// Temperature, unit-converted per `unitSystem`. Used for both water and
    /// ambient/air temperature -- the C-to-F conversion is identical.
    static func celsius(_ value: Double?, unitSystem: UnitSystem = .metric, fractionDigits: Int = 1) -> String {
        guard let value else { return "—" }
        let converted = GraphSeries.waterTemperature.displayValue(value, unitSystem: unitSystem)
        return String(format: "%.\(fractionDigits)f\(GraphSeries.waterTemperature.unitLabel(unitSystem: unitSystem))", converted)
    }

    static func percent(_ value: Double?, fractionDigits: Int = 0) -> String {
        guard let value else { return "—" }
        return String(format: "%.\(fractionDigits)f%%", value)
    }

    static func volts(_ value: Double?, fractionDigits: Int = 2) -> String {
        guard let value else { return "—" }
        return String(format: "%.\(fractionDigits)fV", value)
    }

    static func amps(_ value: Double?, fractionDigits: Int = 2) -> String {
        guard let value else { return "—" }
        return String(format: "%.\(fractionDigits)fA", value)
    }

    static func windSpeed(_ metersPerSecond: Double?, unitSystem: UnitSystem = .metric) -> String {
        guard let metersPerSecond else { return "—" }
        let converted = GraphSeries.windSpeed.displayValue(metersPerSecond, unitSystem: unitSystem)
        return String(format: "%.1f \(GraphSeries.windSpeed.unitLabel(unitSystem: unitSystem))", converted)
    }

    static func humidity(_ value: Double?) -> String {
        percent(value, fractionDigits: 0)
    }

    static func pressure(_ hpa: Double?, unitSystem: UnitSystem = .metric, fractionDigits: Int? = nil) -> String {
        guard let hpa else { return "—" }
        let converted = GraphSeries.barometricPressure.displayValue(hpa, unitSystem: unitSystem)
        let digits = fractionDigits ?? (unitSystem == .imperial ? 2 : 0)
        return String(format: "%.\(digits)f \(GraphSeries.barometricPressure.unitLabel(unitSystem: unitSystem))", converted)
    }

    static func rainfall(_ mm: Double?, unitSystem: UnitSystem = .metric) -> String {
        guard let mm else { return "—" }
        let converted = GraphSeries.rainfall.displayValue(mm, unitSystem: unitSystem)
        let digits = unitSystem == .imperial ? 2 : 1
        return String(format: "%.\(digits)f \(GraphSeries.rainfall.unitLabel(unitSystem: unitSystem))", converted)
    }

    static func compassDirection(_ degrees: Double?) -> String {
        guard let degrees else { return "—" }
        let directions = ["N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
                           "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW"]
        let index = Int((degrees.truncatingRemainder(dividingBy: 360) / 22.5).rounded()) % 16
        return directions[(index + 16) % 16]
    }

    /// A short, human-friendly "how long ago" string (e.g. "5m ago", "2h ago").
    static func relativeTime(from date: Date?, to now: Date = Date()) -> String {
        guard let date else { return "never" }
        let seconds = max(0, now.timeIntervalSince(date))

        if seconds < 60 { return "just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }

    /// A short duration string for a raw seconds count (e.g. device uptime).
    static func relativeDuration(_ totalSeconds: Int?) -> String {
        guard let totalSeconds, totalSeconds >= 0 else { return "—" }
        if totalSeconds < 60 { return "\(totalSeconds)s" }
        if totalSeconds < 3600 { return "\(totalSeconds / 60)m" }
        if totalSeconds < 86400 {
            return "\(totalSeconds / 3600)h \((totalSeconds % 3600) / 60)m"
        }
        return "\(totalSeconds / 86400)d \((totalSeconds % 86400) / 3600)h"
    }
}
