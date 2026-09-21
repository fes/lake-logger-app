import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReadingViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let reading = viewModel.reading {
                        StatusHeaderView(reading: reading, lastFetchedAt: viewModel.lastFetchedAt)
                        WaterLevelCardView(reading: reading, unitSystem: settingsViewModel.unitSystem)
                        BatterySolarCardView(reading: reading)
                        WeatherCardView(reading: reading, unitSystem: settingsViewModel.unitSystem)
                        if !viewModel.history.isEmpty {
                            HistoryChartsSection(
                                readings: viewModel.history,
                                selectedGraphs: settingsViewModel.selectedGraphs,
                                unitSystem: settingsViewModel.unitSystem
                            )
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView(viewModel: settingsViewModel)
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("Settings")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        DeviceDiagnosticsView()
                    } label: {
                        Image(systemName: "wrench.and.screwdriver")
                    }
                    .accessibilityLabel("Device Diagnostics")
                }
            }
            .refreshable {
                await viewModel.refreshAll()
            }
            .task {
                await viewModel.refreshAll()
            }
            .onChange(of: settingsViewModel.historyDays) { newValue in
                Task { await viewModel.setHistoryDays(newValue) }
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
