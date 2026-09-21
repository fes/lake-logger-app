import SwiftUI

struct StatusHeaderView: View {
    let reading: LakeReading
    let lastFetchedAt: Date?

    private var statusColor: Color {
        reading.isOk ? .green : .orange
    }

    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text(reading.isOk ? "Online" : (reading.status ?? "Unknown"))
                    .font(.headline)
                Text("Reading: \(LakeFormat.relativeTime(from: reading.timestamp))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Text("Updated \(LakeFormat.relativeTime(from: lastFetchedAt))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct WaterLevelCardView: View {
    let reading: LakeReading
    var unitSystem: UnitSystem = .metric

    var body: some View {
        HStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 4) {
                Label("Water Level", systemImage: "water.waves")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(LakeFormat.meters(reading.waterLevelM, unitSystem: unitSystem))
                    .font(.title.bold())
            }
            Divider()
            VStack(alignment: .leading, spacing: 4) {
                Label("Water Temp", systemImage: "thermometer.medium")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(LakeFormat.celsius(reading.temperatureC, unitSystem: unitSystem))
                    .font(.title.bold())
            }
            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

struct BatterySolarCardView: View {
    let reading: LakeReading

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Power", systemImage: "bolt.fill")
                .font(.headline)

            HStack {
                powerColumn(
                    title: "Battery",
                    icon: reading.solarChargingBattery == true ? "battery.100.bolt" : "battery.75",
                    voltage: reading.batteryOutputVoltageV,
                    current: reading.batteryOutputCurrentA,
                    present: reading.batteryOutputMonitorPresent,
                    valid: reading.batteryOutputMonitorValid
                )
                Divider()
                powerColumn(
                    title: "Solar",
                    icon: "sun.max.fill",
                    voltage: reading.solarInputVoltageV,
                    current: reading.solarInputCurrentA,
                    present: reading.solarInputMonitorPresent,
                    valid: reading.solarInputMonitorValid
                )
            }

            if let pct = reading.batteryChargeLevelPctApprox {
                ProgressView(value: min(max(pct / 100, 0), 1)) {
                    Text("Charge: \(LakeFormat.percent(pct))")
                        .font(.caption)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func powerColumn(
        title: String,
        icon: String,
        voltage: Double?,
        current: Double?,
        present: Bool?,
        valid: Bool?
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            if present == false {
                Text("Not present")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if valid == false {
                Text("Invalid reading")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else {
                Text(LakeFormat.volts(voltage))
                    .font(.subheadline.bold())
                Text(LakeFormat.amps(current))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct WeatherCardView: View {
    let reading: LakeReading
    var unitSystem: UnitSystem = .metric

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Weather", systemImage: "cloud.sun.fill")
                .font(.headline)

            if reading.weatherEnabled == false {
                Text("Weather station not configured")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else if reading.weatherPresent == false {
                Text("Weather station not responding")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else if reading.weatherValid == false {
                Text(reading.weatherLastError ?? "Weather reading invalid")
                    .font(.subheadline)
                    .foregroundStyle(.orange)
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                    weatherStat("Air Temp", LakeFormat.celsius(reading.weatherAirTemperatureC, unitSystem: unitSystem))
                    weatherStat("Humidity", LakeFormat.humidity(reading.weatherRelativeHumidityPct))
                    weatherStat("Pressure", LakeFormat.pressure(reading.weatherBarometricPressureHpa, unitSystem: unitSystem))
                    weatherStat(
                        "Wind",
                        "\(LakeFormat.windSpeed(reading.weatherWindSpeedMS, unitSystem: unitSystem)) \(LakeFormat.compassDirection(reading.weatherWindDirectionDeg))"
                    )
                    weatherStat("Rainfall", LakeFormat.rainfall(reading.weatherRainfallMm, unitSystem: unitSystem))
                    if let lux = reading.weatherLightLux {
                        weatherStat("Light", String(format: "%.0f lux", lux))
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    @ViewBuilder
    private func weatherStat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
