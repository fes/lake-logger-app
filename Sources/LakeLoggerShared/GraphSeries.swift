import Foundation

/// Every time-series the app can plot in the "History" section. Add a new
/// case here (plus a `value(from:)` mapping) to make a new reading field
/// selectable in Settings -- the history section iterates `allCases`
/// automatically, no other UI changes needed.
enum GraphSeries: String, CaseIterable, Codable, Identifiable {
    case waterLevel
    case waterTemperature
    case ambientTemperature
    case humidity
    case barometricPressure
    case windSpeed
    case rainfall
    case light
    case batteryVoltage
    case solarVoltage
    case batteryChargePercent

    var id: String { rawValue }

    var title: String {
        switch self {
        case .waterLevel: return "Water Level"
        case .waterTemperature: return "Water Temperature"
        case .ambientTemperature: return "Ambient Temperature"
        case .humidity: return "Humidity"
        case .barometricPressure: return "Barometric Pressure"
        case .windSpeed: return "Wind Speed"
        case .rainfall: return "Rainfall"
        case .light: return "Light"
        case .batteryVoltage: return "Battery Voltage"
        case .solarVoltage: return "Solar Voltage"
        case .batteryChargePercent: return "Battery Charge"
        }
    }

    var systemImage: String {
        switch self {
        case .waterLevel: return "water.waves"
        case .waterTemperature: return "thermometer.medium"
        case .ambientTemperature: return "thermometer.sun"
        case .humidity: return "humidity"
        case .barometricPressure: return "gauge"
        case .windSpeed: return "wind"
        case .rainfall: return "cloud.rain"
        case .light: return "sun.max"
        case .batteryVoltage: return "battery.100.bolt"
        case .solarVoltage: return "sun.max.fill"
        case .batteryChargePercent: return "battery.75"
        }
    }

    /// The default set of series shown before the user has customized
    /// anything -- kept small so the history section isn't overwhelming on
    /// first launch, but broad enough to show off the feature.
    static let defaultSelection: Set<GraphSeries> = [
        .waterLevel, .waterTemperature, .ambientTemperature, .batteryVoltage,
    ]

    /// Raw metric-unit value pulled from a reading, before any unit
    /// conversion for display.
    func value(from reading: LakeReading) -> Double? {
        switch self {
        case .waterLevel: return reading.waterLevelM
        case .waterTemperature: return reading.temperatureC
        case .ambientTemperature: return reading.weatherAirTemperatureC
        case .humidity: return reading.weatherRelativeHumidityPct
        case .barometricPressure: return reading.weatherBarometricPressureHpa
        case .windSpeed: return reading.weatherWindSpeedMS
        case .rainfall: return reading.weatherRainfallMm
        case .light: return reading.weatherLightLux
        case .batteryVoltage: return reading.batteryOutputVoltageV
        case .solarVoltage: return reading.solarInputVoltageV
        case .batteryChargePercent: return reading.batteryChargeLevelPctApprox
        }
    }

    /// Converts a raw metric value to the given unit system for charting/
    /// display. Series with no unit conversion (percent, lux, volts) are
    /// unaffected by `unitSystem`.
    func displayValue(_ metricValue: Double, unitSystem: UnitSystem) -> Double {
        guard unitSystem == .imperial else { return metricValue }
        switch self {
        case .waterLevel: return metricValue * 3.28084 // meters -> feet
        case .waterTemperature, .ambientTemperature: return metricValue * 9 / 5 + 32 // C -> F
        case .barometricPressure: return metricValue * 0.0295300 // hPa -> inHg
        case .windSpeed: return metricValue * 2.23694 // m/s -> mph
        case .rainfall: return metricValue / 25.4 // mm -> inches
        case .humidity, .light, .batteryVoltage, .solarVoltage, .batteryChargePercent:
            return metricValue
        }
    }

    func unitLabel(unitSystem: UnitSystem) -> String {
        switch self {
        case .waterLevel: return unitSystem == .imperial ? "ft" : "m"
        case .waterTemperature, .ambientTemperature: return unitSystem == .imperial ? "°F" : "°C"
        case .humidity: return "%"
        case .barometricPressure: return unitSystem == .imperial ? "inHg" : "hPa"
        case .windSpeed: return unitSystem == .imperial ? "mph" : "m/s"
        case .rainfall: return unitSystem == .imperial ? "in" : "mm"
        case .light: return "lux"
        case .batteryVoltage, .solarVoltage: return "V"
        case .batteryChargePercent: return "%"
        }
    }
}
