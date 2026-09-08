import WidgetKit
import SwiftUI

struct LakeLoggerWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: LakeEntry

    var body: some View {
        if let reading = entry.reading {
            switch family {
            case .accessoryRectangular:
                AccessoryRectangularView(reading: reading)
            case .accessoryInline:
                AccessoryInlineView(reading: reading)
            case .systemMedium:
                MediumWidgetView(reading: reading, fetchedAt: entry.fetchedAt)
            case .systemLarge:
                LargeWidgetView(reading: reading, fetchedAt: entry.fetchedAt)
            default:
                SmallWidgetView(reading: reading, fetchedAt: entry.fetchedAt)
            }
        } else {
            UnavailableWidgetView(message: entry.errorMessage ?? "No data yet")
        }
    }
}

private struct SmallWidgetView: View {
    let reading: LakeReading
    let fetchedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Lake", systemImage: "water.waves")
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(LakeFormat.meters(reading.waterLevelM))
                .font(.title2.bold())
                .minimumScaleFactor(0.7)
            Text(LakeFormat.celsius(reading.temperatureC))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
            Text(LakeFormat.relativeTime(from: reading.timestamp))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

private struct MediumWidgetView: View {
    let reading: LakeReading
    let fetchedAt: Date?

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Water Level", systemImage: "water.waves")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(LakeFormat.meters(reading.waterLevelM))
                    .font(.title.bold())
                Text(LakeFormat.celsius(reading.temperatureC))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Divider()
            VStack(alignment: .leading, spacing: 6) {
                statRow(icon: "battery.75", text: LakeFormat.percent(reading.batteryChargeLevelPctApprox))
                statRow(icon: "sun.max.fill", text: LakeFormat.volts(reading.solarInputVoltageV))
                statRow(icon: "thermometer.medium", text: LakeFormat.celsius(reading.weatherAirTemperatureC))
                statRow(icon: "clock", text: LakeFormat.relativeTime(from: reading.timestamp))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
    }

    @ViewBuilder
    private func statRow(icon: String, text: String) -> some View {
        Label(text, systemImage: icon)
            .font(.caption)
            .lineLimit(1)
    }
}

private struct LargeWidgetView: View {
    let reading: LakeReading
    let fetchedAt: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Label("Lake Logger", systemImage: "water.waves")
                    .font(.headline)
                Spacer()
                Text(LakeFormat.relativeTime(from: reading.timestamp))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack {
                VStack(alignment: .leading) {
                    Text("Water Level").font(.caption).foregroundStyle(.secondary)
                    Text(LakeFormat.meters(reading.waterLevelM)).font(.title.bold())
                }
                Spacer()
                VStack(alignment: .leading) {
                    Text("Water Temp").font(.caption).foregroundStyle(.secondary)
                    Text(LakeFormat.celsius(reading.temperatureC)).font(.title.bold())
                }
            }

            Divider()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Battery").font(.caption).foregroundStyle(.secondary)
                    Text(LakeFormat.volts(reading.batteryOutputVoltageV)).font(.subheadline.bold())
                    Text(LakeFormat.percent(reading.batteryChargeLevelPctApprox)).font(.caption)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Solar").font(.caption).foregroundStyle(.secondary)
                    Text(LakeFormat.volts(reading.solarInputVoltageV)).font(.subheadline.bold())
                    Text(LakeFormat.amps(reading.solarInputCurrentA)).font(.caption)
                }
                Spacer()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Air Temp").font(.caption).foregroundStyle(.secondary)
                    Text(LakeFormat.celsius(reading.weatherAirTemperatureC)).font(.subheadline.bold())
                    Text(LakeFormat.humidity(reading.weatherRelativeHumidityPct)).font(.caption)
                }
            }

            Spacer(minLength: 0)
        }
        .padding()
    }
}

private struct AccessoryRectangularView: View {
    let reading: LakeReading

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Lake Level")
                .font(.caption2)
            Text(LakeFormat.meters(reading.waterLevelM))
                .font(.headline)
            Text(LakeFormat.relativeTime(from: reading.timestamp))
                .font(.caption2)
        }
    }
}

private struct AccessoryInlineView: View {
    let reading: LakeReading

    var body: some View {
        Label(LakeFormat.meters(reading.waterLevelM), systemImage: "water.waves")
    }
}

private struct UnavailableWidgetView: View {
    let message: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: "wifi.slash")
                .foregroundStyle(.secondary)
            Text(message)
                .font(.caption2)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
