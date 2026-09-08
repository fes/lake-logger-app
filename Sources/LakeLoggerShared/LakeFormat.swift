import Foundation

enum LakeFormat {
    static func meters(_ value: Double?, fractionDigits: Int = 3) -> String {
        guard let value else { return "—" }
        return String(format: "%.\(fractionDigits)f m", value)
    }

    static func celsius(_ value: Double?, fractionDigits: Int = 1) -> String {
        guard let value else { return "—" }
        return String(format: "%.\(fractionDigits)f°C", value)
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

    static func windSpeed(_ metersPerSecond: Double?) -> String {
        guard let metersPerSecond else { return "—" }
        return String(format: "%.1f m/s", metersPerSecond)
    }

    static func humidity(_ value: Double?) -> String {
        percent(value, fractionDigits: 0)
    }

    static func pressure(_ hpa: Double?) -> String {
        guard let hpa else { return "—" }
        return String(format: "%.0f hPa", hpa)
    }

    static func rainfall(_ mm: Double?) -> String {
        guard let mm else { return "—" }
        return String(format: "%.1f mm", mm)
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
}
