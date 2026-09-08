import Foundation
import WidgetKit

@MainActor
final class ReadingViewModel: ObservableObject {
    @Published private(set) var reading: LakeReading?
    @Published private(set) var history: [LakeReading] = []
    @Published private(set) var lastFetchedAt: Date?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    private let api: LakeApiClient
    private(set) var historyDays: Int

    init(api: LakeApiClient = .shared, historyDays: Int = 7) {
        self.api = api
        self.historyDays = historyDays

        // Show cached data immediately on launch, before the first network
        // round-trip completes, so the UI never opens on an empty state if a
        // widget (or a previous app session) already populated the cache.
        if let cached = SharedReadingCache.load() {
            reading = cached.reading
            lastFetchedAt = cached.fetchedAt
        }
    }

    func refreshAll() async {
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.refreshCurrent() }
            group.addTask { await self.refreshHistory() }
        }
    }

    func refreshCurrent() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }

        do {
            let latest = try await api.fetchCurrent()
            reading = latest
            lastFetchedAt = Date()
            if let latest {
                SharedReadingCache.save(latest)
                // Nudge the widget to pick up the freshly fetched reading
                // right away instead of waiting for its own timeline slot.
                WidgetCenter.shared.reloadAllTimelines()
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func refreshHistory() async {
        do {
            history = try await api.fetchHistory(days: historyDays)
        } catch {
            // History is a secondary/nice-to-have view; don't clobber a
            // successful "current reading" error state with a history fetch
            // failure. Only surface it if we have nothing else to show.
            if reading == nil {
                errorMessage = error.localizedDescription
            }
        }
    }

    func setHistoryDays(_ days: Int) async {
        guard days != historyDays else { return }
        historyDays = days
        await refreshHistory()
    }
}
