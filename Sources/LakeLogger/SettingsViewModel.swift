import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var unitSystem: UnitSystem {
        didSet {
            guard unitSystem != oldValue else { return }
            AppSettingsStore.saveUnitSystem(unitSystem)
        }
    }

    @Published var selectedGraphs: Set<GraphSeries> {
        didSet {
            guard selectedGraphs != oldValue else { return }
            AppSettingsStore.saveSelectedGraphs(selectedGraphs)
        }
    }

    /// How many days of history charts/requests should cover. Persisted
    /// separately from the in-flight fetch in `ReadingViewModel` -- this is
    /// the user's saved preference; `ContentView` observes it and tells
    /// `ReadingViewModel` to refetch whenever it changes.
    @Published var historyDays: Int {
        didSet {
            guard historyDays != oldValue else { return }
            AppSettingsStore.saveHistoryDays(historyDays)
        }
    }

    let availableHistoryDays = AppSettingsStore.availableHistoryDays

    init() {
        unitSystem = AppSettingsStore.loadUnitSystem()
        selectedGraphs = AppSettingsStore.loadSelectedGraphs()
        historyDays = AppSettingsStore.loadHistoryDays()
    }

    func isSelected(_ series: GraphSeries) -> Bool {
        selectedGraphs.contains(series)
    }

    func setSelected(_ series: GraphSeries, isSelected: Bool) {
        if isSelected {
            selectedGraphs.insert(series)
        } else {
            selectedGraphs.remove(series)
        }
    }

    /// `GraphSeries.allCases` in a stable, display-friendly order (grouped
    /// water/weather/power rather than declaration order).
    var orderedGraphSeries: [GraphSeries] {
        GraphSeries.allCases.sorted { $0.title < $1.title }
    }
}
