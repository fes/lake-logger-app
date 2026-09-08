import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReadingViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let reading = viewModel.reading {
                        StatusHeaderView(reading: reading, lastFetchedAt: viewModel.lastFetchedAt)
                        WaterLevelCardView(reading: reading)
                        BatterySolarCardView(reading: reading)
                        WeatherCardView(reading: reading)
                        if !viewModel.history.isEmpty {
                            WaterLevelHistoryChart(readings: viewModel.history)
                        }
                    } else if viewModel.isLoading {
                        ProgressView("Loading latest reading…")
                            .padding(.top, 80)
                    } else {
                        EmptyStateView(message: viewModel.errorMessage ?? "No readings available yet.")
                            .padding(.top, 80)
                    }

                    if let errorMessage = viewModel.errorMessage, viewModel.reading != nil {
                        Label(errorMessage, systemImage: "exclamationmark.triangle")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                            .padding(.horizontal)
                    }
                }
                .padding()
            }
            .navigationTitle("Lake Logger")
            .refreshable {
                await viewModel.refreshAll()
            }
            .task {
                await viewModel.refreshAll()
            }
        }
    }
}

private struct EmptyStateView: View {
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 40))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}

#Preview {
    ContentView()
}
