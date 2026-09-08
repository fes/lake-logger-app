import Foundation

/// A single lake logger reading as returned by the fesLabs API
/// (`GET /api/lake/current` and `GET /api/lake/history`).
///
/// Field names intentionally mirror the API's camelCase JSON keys 1:1 so no
/// custom `CodingKeys` mapping is required. Keep this in sync with
/// `functions/src/index.ts`'s `LakeReading` type in the feslabs-web repo.
struct LakeReading: Codable, Identifiable, Equatable {
    var id: String { timestampUtc ?? UUID().uuidString }

    var receivedAtUtc: String?
    var timestampUtc: String?
    var deviceId: String?
    var modbusId: Int?
    var serialNumber: String?
    var firmware: String?

    var waterLevelM: Double?
    var temperatureC: Double?

    var batteryOutputMonitorPresent: Bool?
    var batteryOutputMonitorValid: Bool?
    var batteryOutputVoltageV: Double?
    var batteryOutputCurrentA: Double?
    var batteryOutputPowerW: Double?

    var solarInputMonitorPresent: Bool?
    var solarInputMonitorValid: Bool?
    var solarInputVoltageV: Double?
    var solarInputCurrentA: Double?
    var solarInputPowerW: Double?

    var batteryChargeLevelPctApprox: Double?
    var solarChargingBattery: Bool?

    var weatherEnabled: Bool?
    var weatherPresent: Bool?
    var weatherValid: Bool?
    var weatherModbusId: Int?
    var weatherReadUtc: String?
    var weatherAirTemperatureC: Double?
    var weatherRelativeHumidityPct: Double?
    var weatherBarometricPressureHpa: Double?
    var weatherWindSpeedMS: Double?
    var weatherWindDirectionDeg: Double?
    var weatherRainfallMm: Double?
    var weatherLightLux: Double?
    var weatherLastError: String?

    var weatherSummarySampleCount: Int?
    var weatherSummaryStartUtc: String?
    var weatherSummaryEndUtc: String?
    var weatherAirTemperatureCAvg: Double?
    var weatherAirTemperatureCMin: Double?
    var weatherAirTemperatureCMax: Double?
    var weatherRelativeHumidityPctAvg: Double?
    var weatherRelativeHumidityPctMin: Double?
    var weatherRelativeHumidityPctMax: Double?
    var weatherBarometricPressureHpaAvg: Double?
    var weatherBarometricPressureHpaMin: Double?
    var weatherBarometricPressureHpaMax: Double?
    var weatherWindSpeedMSAvg: Double?
    var weatherWindSpeedMSMin: Double?
    var weatherWindSpeedMSMax: Double?
    var weatherWindDirectionDegAvg: Double?
    var weatherLightLuxAvg: Double?
    var weatherLightLuxMin: Double?
    var weatherLightLuxMax: Double?
    var weatherRainfallIntervalMm: Double?
    var weatherRainfallCounterReset: Bool?

    var status: String?
    var uploadSource: String?
}

extension LakeReading {
    /// Parses `timestampUtc` into a `Date`.
    var timestamp: Date? {
        Self.parseIso8601(timestampUtc)
    }

    var weatherReadTimestamp: Date? {
        Self.parseIso8601(weatherReadUtc)
    }

    var isOk: Bool {
        (status ?? "").uppercased() == "OK"
    }

    /// Parses either fractional-second (`...SSSZ`, from the firmware/ingest
    /// path) or whole-second (`...Z`, from on-device UTC formatting) ISO 8601
    /// timestamps, matching the two shapes the API can return.
    static func parseIso8601(_ value: String?) -> Date? {
        guard let value, !value.isEmpty else { return nil }
        return ISO8601DateFormatter.lakeLoggerWithFractionalSeconds.date(from: value)
            ?? ISO8601DateFormatter.lakeLoggerWholeSeconds.date(from: value)
    }
}

extension ISO8601DateFormatter {
    static let lakeLoggerWithFractionalSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let lakeLoggerWholeSeconds: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()
}
