import SwiftUI
import Charts

/// Renders one history chart per series the user has enabled in Settings
/// (`AppSettingsStore.loadSelectedGraphs()`), in a stable order matching the
/// Settings screen's list.
struct HistoryChartsSection: View {
    let readings: [LakeReading]
    let selectedGraphs: Set<GraphSeries>
    let unitSystem: UnitSystem

    private var orderedSelection: [GraphSeries] {
        GraphSeries.allCases
            .filter { selectedGraphs.contains($0) }
            .sorted { $0.title < $1.title }
    }

    var body: some View {
        ForEach(orderedSelection) { series in
            SeriesHistoryChart(series: series, readings: readings, unitSystem: unitSystem)
        }
    }
}

private struct SeriesHistoryChart: View {
    let series: GraphSeries
    let readings: [LakeReading]
    let unitSystem: UnitSystem

    private var points: [(date: Date, value: Double)] {
        readings.compactMap { reading in
            guard let date = reading.timestamp, let rawValue = series.value(from: reading) else { return nil }
            return (date, series.displayValue(rawValue, unitSystem: unitSystem))
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("\(series.title) History", systemImage: series.systemImage)
                .font(.headline)

            if points.isEmpty {
                Text("Not enough history data yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(points, id: \.date) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value(series.title, point.value)
                    )
                    .interpolationMethod(.monotone)
                }
                .frame(height: 180)
                .chartYAxisLabel(series.unitLabel(unitSystem: unitSystem))
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
