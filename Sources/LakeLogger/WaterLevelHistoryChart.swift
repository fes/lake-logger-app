import SwiftUI
import Charts

struct WaterLevelHistoryChart: View {
    let readings: [LakeReading]

    private var points: [(date: Date, level: Double)] {
        readings.compactMap { reading in
            guard let date = reading.timestamp, let level = reading.waterLevelM else { return nil }
            return (date, level)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Water Level History", systemImage: "chart.xyaxis.line")
                .font(.headline)

            if points.isEmpty {
                Text("Not enough history data yet.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                Chart(points, id: \.date) { point in
                    LineMark(
                        x: .value("Time", point.date),
                        y: .value("Water Level (m)", point.level)
                    )
                    .interpolationMethod(.monotone)
                }
                .frame(height: 180)
                .chartYAxisLabel("meters")
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}
