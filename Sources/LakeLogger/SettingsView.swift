import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel

    var body: some View {
        Form {
            Section {
                Picker("Units", selection: $viewModel.unitSystem) {
                    ForEach(UnitSystem.allCases) { system in
                        Text(system.displayName).tag(system)
                    }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Units")
            } footer: {
                Text("Applies to water level, temperature, wind speed, pressure, and rainfall throughout the app.")
            }

            Section {
                Picker("Duration", selection: $viewModel.historyDays) {
                    ForEach(viewModel.availableHistoryDays, id: \.self) { days in
                        Text(days == 1 ? "1 day" : "\(days) days").tag(days)
                    }
                }
            } header: {
                Text("History duration")
            } footer: {
                Text("How far back the history charts (and the data fetched for them) go.")
            }

            Section {
                ForEach(viewModel.orderedGraphSeries) { series in
                    Toggle(isOn: Binding(
                        get: { viewModel.isSelected(series) },
                        set: { viewModel.setSelected(series, isSelected: $0) }
                    )) {
                        Label(series.title, systemImage: series.systemImage)
                    }
                }
            } header: {
                Text("History graphs")
            } footer: {
                Text("Choose which readings show as history charts on the dashboard.")
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView(viewModel: SettingsViewModel())
    }
}
