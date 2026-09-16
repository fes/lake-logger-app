import Foundation

/// Mirrors (a useful subset of) the fields returned by the logger device's
/// own `/status` endpoint, reachable only when the phone is on the same
/// local network as the device (it is not exposed to the internet).
///
/// All fields are optional so that firmware version drift (fields added,
/// renamed, or removed on the device) degrades gracefully to "unknown"
/// instead of failing to decode the whole response.
struct DeviceStatus: Codable {
    var deviceId: String?
    var siteHealth: String?
    var ip: String?
    var wifiConnected: Bool?
    var wifiRssiDbm: Int?
    var uptimeS: Int?
    var lastSystemResetReason: String?

    var clockValid: Bool?
    var clockNowUtc: String?
    var lastNtpSyncAge: String?
    var consecutiveNtpFailures: Int?
    var ntpSyncDeltaSeconds: Int?
    var ntpLargestObservedSkewSeconds: Int?
    var ntpSkewSampleCount: Int?

    var sensorFound: Bool?
    var lastSensorDiscoveryAttemptSucceeded: Bool?
    var consecutiveSensorDiscoveryFailures: Int?

    var uploadEndpointHost: String?
    var lastSuccessfulUploadUtc: String?
    var lastSuccessfulUploadAge: String?
    var lastUploadError: String?
    var lastUploadErrorUtc: String?
    var consecutiveUploadFailures: Int?
    var successfulUploads: Int?
    var failedUploads: Int?
    var backlogCount: Int?
    var droppedBacklogEntries: Int?

    var lastSuccessfulProbeReadUtc: String?
    var lastSuccessfulProbeReadAge: String?
    var successfulProbeReads: Int?
    var failedProbeReads: Int?

    var cachedProbeBatteryOutputVoltageV: Double?
    var cachedProbeSolarInputVoltageV: Double?
    var batteryChargeLevelPctApprox: Double?

    enum CodingKeys: String, CodingKey {
        case deviceId = "device_id"
        case siteHealth = "site_health"
        case ip
        case wifiConnected = "wifi_connected"
        case wifiRssiDbm = "wifi_rssi_dbm"
        case uptimeS = "uptime_s"
        case lastSystemResetReason = "last_system_reset_reason"
        case clockValid = "clock_valid"
        case clockNowUtc = "clock_now_utc"
        case lastNtpSyncAge = "last_ntp_sync_age"
        case consecutiveNtpFailures = "consecutive_ntp_failures"
        case ntpSyncDeltaSeconds = "ntp_sync_delta_seconds"
        case ntpLargestObservedSkewSeconds = "ntp_largest_observed_skew_seconds"
        case ntpSkewSampleCount = "ntp_skew_sample_count"
        case sensorFound = "sensor_found"
        case lastSensorDiscoveryAttemptSucceeded = "last_sensor_discovery_attempt_succeeded"
        case consecutiveSensorDiscoveryFailures = "consecutive_sensor_discovery_failures"
        case uploadEndpointHost = "upload_endpoint_host"
        case lastSuccessfulUploadUtc = "last_successful_upload_utc"
        case lastSuccessfulUploadAge = "last_successful_upload_age"
        case lastUploadError = "last_upload_error"
        case lastUploadErrorUtc = "last_upload_error_utc"
        case consecutiveUploadFailures = "consecutive_upload_failures"
        case successfulUploads = "successful_uploads"
        case failedUploads = "failed_uploads"
        case backlogCount = "backlog_count"
        case droppedBacklogEntries = "dropped_backlog_entries"
        case lastSuccessfulProbeReadUtc = "last_successful_probe_read_utc"
        case lastSuccessfulProbeReadAge = "last_successful_probe_read_age"
        case successfulProbeReads = "successful_probe_reads"
        case failedProbeReads = "failed_probe_reads"
        case cachedProbeBatteryOutputVoltageV = "cached_probe_battery_output_voltage_v"
        case cachedProbeSolarInputVoltageV = "cached_probe_solar_input_voltage_v"
        case batteryChargeLevelPctApprox = "battery_charge_level_pct_approx"
    }
}

/// Mirrors the on-demand `/probe` endpoint: forces a fresh sensor read and
/// returns it immediately, bypassing both the device's own upload schedule
/// and the feslabs.com cloud cache entirely. Useful for confirming the
/// physical sensors/RS485 bus are healthy even when cloud uploads are
/// stalled (as happened with the NTP-skew scheduler bug).
struct DeviceProbeReading: Codable {
    var ok: Bool?
    var timestampUtc: String?
    var waterLevelM: Double?
    var temperatureC: Double?
    var batteryOutputVoltageV: Double?
    var solarInputVoltageV: Double?
    var batteryChargeLevelPctApprox: Double?
    var weatherAirTemperatureC: Double?
    var weatherRelativeHumidityPct: Double?

    enum CodingKeys: String, CodingKey {
        case ok
        case timestampUtc = "timestamp_utc"
        case waterLevelM = "water_level_m"
        case temperatureC = "temperature_c"
        case batteryOutputVoltageV = "battery_output_voltage_v"
        case solarInputVoltageV = "solar_input_voltage_v"
        case batteryChargeLevelPctApprox = "battery_charge_level_pct_approx"
        case weatherAirTemperatureC = "weather_air_temperature_c"
        case weatherRelativeHumidityPct = "weather_relative_humidity_pct"
    }
}
