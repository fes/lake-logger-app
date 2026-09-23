import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = ReadingViewModel()
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.scenePhase) private var scenePhase

    /// How often to auto-retry the current/history fetch while this view is
    /// visible. Guards against a single dropped/cancelled request (e.g. from
    /// a brief network hiccup or the app being backgrounded mid-request)
    /// leaving a stale error banner on screen indefinitely with no way to
    /// self-heal short of the user manually pulling to refresh.
    private static let autoRefreshInterval: Duration = .seconds(60)

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
                // Loop instead of a one-shot fetch so a transient failure
                // (timeout, cancellation, brief connectivity drop) doesn't
                // leave the UI stuck showing a stale error forever.
                while !Task.isCancelled {
                    await viewModel.refreshAll()
                    try? await Task.sleep(for: Self.autoRefreshInterval)
                }
            }
            .onChange(of: settingsViewModel.historyDays) { newValue in
                Task { await viewModel.setHistoryDays(newValue) }
            }
            .onChange(of: scenePhase) { newPhase in
                // Refresh immediately when the app comes back to the
                // foreground, rather than waiting for the next auto-refresh
                // tick, so returning from the background always shows
                // current data.
                if newPhase == .active {
                    Task { await viewModel.refreshAll() }
                }
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
